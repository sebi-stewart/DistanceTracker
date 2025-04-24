//
//  StepperView.swift
//  DistanceTracker
//
//  Created by Sebastian Stewart on 24/04/2025.
//

import SwiftUI
import Foundation
import MapKit

struct StepperView: View {
    @Binding var value: Double
    @State var distanceMeasurement: DistanceMeasurements = .kilometers
    @State var textEditNum: Int = 0
    @FocusState var isInputActive: Bool
    
    let maxStep = 20037.0 // This is the antipodal distance of earth, aka furthest point you can be away from one another
        
    func getFormatter() -> DistanceFormatter{
        let formatter = DistanceFormatter()
        formatter.measurement = distanceMeasurement.description
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
    
    func updateDistanceMeasurement() {
        if value < 3{
            distanceMeasurement = distanceMeasurement.smallerMeasurements
        } else if value > 3 {
            distanceMeasurement = distanceMeasurement.largerMeasurements
        }
    }
    
    func updateDisplayValue(){
        textEditNum = Int(convertToSelectedMeasurement().rounded())
    }
    
    func updateAll(){
        updateDistanceMeasurement()
        updateDisplayValue()
    }
    
    func convertToSelectedMeasurement() -> Double {
        return value * distanceMeasurement.conversionFromKM
    }
    
    func convertFromSelectedMeasurement(newValue: Double) -> Double {
        return newValue / distanceMeasurement.conversionFromKM
    }


    var body: some View {
        HStack{
            TextField("Value", value: $textEditNum, formatter: getFormatter(), onCommit: {
                value = convertFromSelectedMeasurement(newValue: Double(textEditNum))
                value = min(max(value, 0), maxStep)
            })
            .keyboardType(.numberPad)
            .focused($isInputActive)
            .frame(minWidth: 80)
            .toolbar {
                if isInputActive {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Done") {
                            isInputActive = false
                        }
                    }
                }
            }
            
            Stepper {
//                Text("\(Int(convertToSelectedMeasurement().rounded())) \(distanceMeasurement.description)")
            } onIncrement: {
                incrementStep()
            } onDecrement: {
                decrementStep()
            }
            
        } .onAppear {
            updateAll()
        } .onChange(of: value) {
            updateAll()
        }
    }
}

class DistanceFormatter: Formatter {
    var measurement: String = "undefined"
    
    override func string(for obj: Any?) -> String?{
        guard obj != nil else {return "Nil Object"}
        guard obj is Int else {return "Not Int Object"}
        return "\((obj as! Int).formatted()) \(measurement)"
    }
    
    func extractFirstInteger(from input: String) -> Int {
        // Match the first sequence of digits, possibly with commas in it
        let pattern = #"(\d[\d,\s]*)"#
        
        if let match = input.range(of: pattern, options: .regularExpression) {
            let matchedString = String(input[match])
            let digitsOnly = matchedString.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
            return Int(digitsOnly) ?? 0
        }
        
        // Fallback to 0 if no match
        return 0
    }

    override func getObjectValue(_ obj: AutoreleasingUnsafeMutablePointer<AnyObject?>?, for string: String, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
        
        guard !string.isEmpty else { return false }
        
        let number = extractFirstInteger(from: string)
//        print("in getObjectValue(), string = \(trimmedString), value = \(number)")
        obj?.pointee = number as AnyObject
        return true
    }
}
