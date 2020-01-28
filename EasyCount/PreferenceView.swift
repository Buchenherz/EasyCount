//
//  PreferenceView.swift
//  EasyCount
//
//  Created by Zoë Pfister on 28.01.20.
//  Copyright © 2020 Zoë Pfister. All rights reserved.
//

import Foundation
import SwiftUI

private let dateFormatter: DateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .medium
    dateFormatter.timeStyle = .medium
    return dateFormatter
}()

struct PreferenceView: View {
    // Actual settings variable
    @ObservedObject var settings = UserSettings()

    var body: some View {
        VStack {
            Spacer(minLength: 50.0)
            Text("Counter settings").font(.title).fontWeight(.heavy).frame(maxWidth: .infinity, alignment: .leading).padding(.leading)
            Stepper(value: $settings.stepCount, in: 0 ... 100, step: 1) { Text("Step counter per tap: \(self.settings.stepCount)").fontWeight(.heavy)}.padding(.leading).padding(.trailing)
            Toggle(isOn: $settings.startCountingAtZero) {Text("Start counting at 0").fontWeight(.heavy)}.padding(.leading).padding(.trailing).padding(.top, 10.0)
            
            Spacer(minLength: 50.0)
            Text("List padding").font(.title).fontWeight(.heavy).frame(maxWidth: .infinity, alignment: .leading).padding(.leading)
            Slider(value: $settings.listPadding, in: 1.0 ... 15.0, step: 1.0, onEditingChanged: { _ in }).padding(.leading).padding(.trailing)
            Text("\(Int(self.settings.listPadding))").fontWeight(.heavy)
            List {
                VStack(alignment: .leading) {
                    Text("Counter 1 Name")
                    Text("\(Date(), formatter: dateFormatter)")
                        .fontWeight(.light)
                        .font(.system(size: 14))
                }.padding(CGFloat(self.settings.listPadding))
                VStack(alignment: .leading) {
                    Text("Counter 2 Name")
                    Text("\(Date(), formatter: dateFormatter)")
                        .fontWeight(.light)
                        .font(.system(size: 14))
                }.padding(CGFloat(self.settings.listPadding))
            }
        }
    }
}