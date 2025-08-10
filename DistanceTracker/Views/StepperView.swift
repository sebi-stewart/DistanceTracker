//
//  StepperView.swift
//  DistanceTracker
//
//  Created by Sebastian Stewart on 24/04/2025.
//

import SwiftUI
import Foundation
import MapKit
import Combine

struct StepperView: View {
    @Binding var value: Double
    @State var distanceMeasurement: DistanceMeasurements = .kilometers
    @FocusState var isInputActive: Bool
    
    @State private var textEditNum: String = "0"
    let maxStep = 20037.0 // This is the antipodal distance of earth, aka furthest point you can be away from one another
    let textLimit = 10
        
    func getFormatter() -> NumberFormatter{
        let formatter = NumberFormatter()
        return formatter
    }

    func incrementStep() {
        if value == maxStep { value = 0; return}
        var displayValue = convertToSelectedMeasurement()
        displayValue = pow(10, log10(Double(displayValue+1)).rounded(.up))
        value = convertFromSelectedMeasurement(newValue: displayValue)
        if value >= maxStep { value = maxStep }
    }

    func decrementStep() {
        if value <= 0 { value = maxStep; return}
        var displayValue = convertToSelectedMeasurement()
        displayValue =  pow(10, log10(Double(displayValue-1)).rounded(.down))
        value = convertFromSelectedMeasurement(newValue: displayValue)
    }
    
    func limitText(_ upper: Int){
        if textEditNum.count > upper {
            textEditNum = String(textEditNum.prefix(upper))
        }
    }
    
    func updateDistanceMeasurement() {
        if value < 3{
            distanceMeasurement = distanceMeasurement.smallerMeasurements
        } else if value > 3 {
            distanceMeasurement = distanceMeasurement.largerMeasurements
        }
    }
    
    func clampValue(){
        value = min(max(value, 0), maxStep)
    }
    
    func updateDisplayValue(){
        textEditNum = Int(convertToSelectedMeasurement().rounded()).formatted()
    }
    
    func updateAll(){
        print("Update All Called")
        clampValue()
        updateDistanceMeasurement()
        updateDisplayValue()
    }
    
    func convertToSelectedMeasurement() -> Double {
        return value * distanceMeasurement.conversionFromKM
    }
    
    func convertFromSelectedMeasurement(newValue: Double) -> Double {
        return newValue / distanceMeasurement.conversionFromKM
    }
    
    func extractFirstDecimal(from input: String) -> Double {
        // Match the first sequence of digits, possibly with commas in it
        var commaCount: Int = 0
        var periodCount: Int = 0
        var isCommaFirst: Bool? = nil
        
        for (_, char) in input.enumerated() {
            if char == ","{
                commaCount += 1
                if isCommaFirst == nil { isCommaFirst = true }
            } else if char == "." {
                periodCount += 1
                if isCommaFirst == nil { isCommaFirst = false }
            }
            
        }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        
        let usLocale = Locale(identifier: "en_US")
        let frLocale = Locale(identifier: "fr_FR")
        
        if commaCount == 0 && periodCount == 0 {
            return formatter.number(from: input)?.doubleValue ?? 0.0
        }
        
        if commaCount != 0 && periodCount != 0 {
            let charToRemove = isCommaFirst! ? "," : "."
            let parsedInput = input.replacingOccurrences(of: charToRemove, with: "")
            formatter.locale = isCommaFirst! ? usLocale : frLocale
            return formatter.number(from: parsedInput)?.doubleValue ?? 0.0
        }
        
        let userLocale: Locale = .current
        let groupingSeparator = userLocale.groupingSeparator ?? " "
        let parsedInput = input.replacingOccurrences(of: groupingSeparator, with: "")
        formatter.locale = userLocale
        return formatter.number(from: parsedInput)?.doubleValue ?? 0.0
    }


    var body: some View {
        HStack{
            HStack(spacing: 1){
                TextField("Value", text: $textEditNum)
                .onAppear { updateAll() }
                .onChange(of: value) { updateAll() }
                .onReceive(Just(textEditNum)) { _ in limitText(textLimit)}
                .focused($isInputActive)
                .keyboardType(.numberPad)
                .toolbar {
                    if isInputActive {
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()
                            Button("Done") {
                                isInputActive = false
                                print("Done Clicked - \(textEditNum)")
                                let extractedNum = extractFirstDecimal(from: textEditNum)
                                print("Extracted Number - \(extractedNum)")
                                value = convertFromSelectedMeasurement(newValue: extractedNum)
                                print("Done Clicked")
                            }
                        }
                    }
                }
                .background(
                    HStack(spacing: 2) {
                        Text(String(textEditNum))
                            .hidden()
                        Text(distanceMeasurement.description)
                        Spacer()
                    }
                )
                
//                Spacer()
            }
            Spacer()
            
            Stepper {
//                Text("\(Int(convertToSelectedMeasurement().rounded())) \(distanceMeasurement.description)")
            } onIncrement: {
                incrementStep()
            } onDecrement: {
                decrementStep()
            }
            .fixedSize()
            
        }
    }
}
