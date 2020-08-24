//
//  ViewController.swift
//  HealthKitTest
//
//  Created by admin on 2020/8/24.
//  Copyright © 2020 zhumj. All rights reserved.
//

import UIKit
import HealthKit

class ViewController: UIViewController {
    
    @IBOutlet weak var tvText: UITextView!
    
    let healthKitStore:HKHealthStore = HKHealthStore()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //内容不r允许滚动
//        tvText.isScrollEnabled = false
        //内容缩进为0（去除左右边距）
//        tvText.textContainer.lineFragmentPadding = 0
        //设置不可编辑
        tvText.isEditable = false
        //文本边距设为0（去除上下边距）
//        tvText.textContainerInset = .zero
        
        healthDataAvailable()
        
    }
    
    @IBAction func getInfoAction(_ sender: Any) {
        self.getInfo()
    }
    
    //查询苹果健康是否可用
    private func healthDataAvailable() {
        let isHealthDataAvailable = HKHealthStore.isHealthDataAvailable()
        if isHealthDataAvailable {
            tvText.insertText("苹果健康可用")
            self.healthDataAuthorization()
        } else {
            tvText.insertText("苹果健康不可用")
        }
    }

    //苹果健康授权
    private func healthDataAuthorization() {
        //   需要获取的数据  出生年月  血型 性别 体重 身高
        let healthKitTypesToRead = NSSet(array:[
            HKObjectType.characteristicType(forIdentifier: HKCharacteristicTypeIdentifier.dateOfBirth) as Any ,
            HKObjectType.characteristicType(forIdentifier: HKCharacteristicTypeIdentifier.bloodType) as Any,
            HKObjectType.characteristicType(forIdentifier: HKCharacteristicTypeIdentifier.biologicalSex) as Any,
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyMass) as Any,
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.height) as Any,
            HKObjectType.workoutType()
            ])
         
        //需要写入的数据
        let healthKitTypesToWrite = NSSet(array:[
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyMassIndex) as Any,
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.activeEnergyBurned) as Any,
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.distanceWalkingRunning) as Any,
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount) as Any,
            HKQuantityType.workoutType()
            ])
        
        // 授权
        healthKitStore.requestAuthorization(toShare: healthKitTypesToWrite as? Set<HKSampleType>, read: healthKitTypesToRead as? Set<HKObjectType>) { (success, error) in
            DispatchQueue.main.async {
                if success {
                    self.tvText.insertText("\n苹果健康授权成功，开始获取数据")
                } else {
                    self.tvText.insertText("\n苹果健康授权失败：\(error?.localizedDescription ?? "未知")")
                }
            }
        };
    }
    
    // 获取数据
    private func getInfo(){
        let healthKitStore = HKHealthStore()
        
        do {
            let unwrappedBiologicalSex = try  healthKitStore.biologicalSex()
            switch unwrappedBiologicalSex.biologicalSex {
            case .notSet:
                self.tvText.insertText("\n性别：没有设置")
                break
            case .female:
                self.tvText.insertText("\n性别：女")
                break
            case .male:
                self.tvText.insertText("\n性别：男")
                break
            default:
                self.tvText.insertText("\n性别：其他")
                break
            }
        } catch let error {
            self.tvText.insertText("\n没有获取性别的权限：\(error.localizedDescription)")
        }
        
        do {
            let birthDate = try  healthKitStore.dateOfBirthComponents()
            self.tvText.insertText("\n出生日期：\(birthDate.year!)年\(birthDate.month!)月\(birthDate.day!)日")
        } catch let error {
            self.tvText.insertText("\n没有获取生日的权限：\(error.localizedDescription)")
        }
        
        self.readMostRecentSample(identifier: HKQuantityTypeIdentifier.height) { (heigt, error) in
            if error != nil {
                DispatchQueue.main.async {
                    self.tvText.insertText("\n身高获取失败：\(error?.localizedDescription ?? error?.domain ?? "未知")")
                }
                return
            }
            
            var heightLocalizedString = "0.0m"
            let mHeight = heigt as? HKQuantitySample;
            if let meters = mHeight?.quantity.doubleValue(for: HKUnit.meterUnit(with: HKMetricPrefix.centi)) {
                let heightFormatter = LengthFormatter()
                heightFormatter.isForPersonHeightUse = true;
                // 175cm
                heightLocalizedString = heightFormatter.string(fromValue: meters, unit: LengthFormatter.Unit.centimeter)
            }
            DispatchQueue.main.async {
                self.tvText.insertText("\n身高：\(heightLocalizedString)")
            }
        }
        
        self.readMostRecentSample(identifier: HKQuantityTypeIdentifier.bodyMass) { (weight, error) in
            if error != nil {
                DispatchQueue.main.async {
                    self.tvText.insertText("\n体重(bodyMass)获取失败：\(error?.localizedDescription ?? error?.domain ?? "未知")")
                }
                return
            }
            
            var weightLocalizedString = "0.0kg"
            let mWeight = weight as? HKQuantitySample;
            if let meters = mWeight?.quantity.doubleValue(for: HKUnit.gramUnit(with: HKMetricPrefix.kilo)) {
                let weightFormatter = MassFormatter()
                weightFormatter.isForPersonMassUse = true;
                // 75kg
                weightLocalizedString = weightFormatter.string(fromValue: meters, unit: MassFormatter.Unit.kilogram)
            }
            DispatchQueue.main.async {
                self.tvText.insertText("\n体重(bodyMass)：\(weightLocalizedString)")
            }
        }
        
    }
    
    // 查询咯
    private func readMostRecentSample(identifier: HKQuantityTypeIdentifier, completion: ((HKSample?, NSError?) -> Void)?){
        // 1. Construct an HKSampleType for Height
        let sampleType = HKSampleType.quantityType(forIdentifier: identifier)!
        // 2. Build the Predicate
        let past = NSDate.distantPast as Date
        let now = Date()
        let mostRecentPredicate = HKQuery.predicateForSamples(withStart: past, end: now)
        // 3. Build the sort descriptor to return the samples in descending order
        let sortDescriptor = NSSortDescriptor(key:HKSampleSortIdentifierStartDate, ascending: false)
        // 4. we want to limit the number of samples returned by the query to just 1 (the most recent)
        let limit = 1
        // 5. Build samples query
        let sampleQuery = HKSampleQuery(sampleType: sampleType, predicate: mostRecentPredicate, limit: limit, sortDescriptors: [sortDescriptor]){ (sampleQuery, results, error ) -> Void in
            if error != nil {
                completion?(nil,error as NSError?)
                return;
            }
            // Get the first sample
            let mostRecentSample: HKSample? = results?.first
            // Execute the completion closure
            completion?(mostRecentSample,nil)
        }
        // 6. Execute the Query
        self.healthKitStore.execute(sampleQuery)
    }
}

