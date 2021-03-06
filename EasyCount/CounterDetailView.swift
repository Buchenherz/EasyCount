//
//  CounterDetailView.swift
//  EasyCount
//
//  Created by Zoë Pfister on 28.01.20.
//  Copyright © 2020 Zoë Pfister. All rights reserved.
//

import Foundation
import SwiftUI

struct CounterDetailView: View {
    // Parent counter of CounterDetail
    var counter: Counter

    // Variable for creating a new Counter within DetailView
    @State private var newText: String = ""

    // Boolian to show the Share Sheet
    @State private var showShareSheet = false

    // URL that eventually stores the CSV export file
    @State private var csvFileURL: URL?
    @State private var errorAlertIsPresented = false
    // Not ideal if multiple errors may happen at the same time
    @State private var errorText = ""

    // Fetch request and result
    var fetchRequest: FetchRequest<CounterDetail>
    var counterDetails: FetchedResults<CounterDetail> { fetchRequest.wrappedValue }

    @Environment(\.managedObjectContext)
    var viewContext

    // User settings
    @State private var settings = UserSettings()

    // Convenience Init to allow a fetch request using a filter predicate (in this case, the current
    // counter. Source:
    // https://www.hackingwithswift.com/quick-start/ios-swiftui/dynamically-filtering-fetchrequest-with-swiftui
    init(filter: Counter) {
        fetchRequest = FetchRequest(
            entity: CounterDetail.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \CounterDetail.name, ascending: true)],
            predicate: NSPredicate(format: "counter == %@", filter),
            animation: .default)
        counter = filter
    }

    // Allows for creation of a new detailcounter using the name stored within the newText state variable
    fileprivate func createDetailCounter() {
        if self.newText != "" {
            // Creating a new Detailcounter where the actual couting will occur. The initial value is set to the step amount if the user specified that counting should not start at 0.
            let newCounter = self.settings.startCountingAtZero
                ? CounterDetail.create(in: self.viewContext, startCount: Int64(0))
                : CounterDetail.create(in: self.viewContext, startCount: Int64(self.settings.stepCount))
            newCounter.counter = self.counter
            newCounter.name = self.newText
            self.newText = ""
        }
    }
    
    var body: some View {
        VStack {
            List {
                ForEach(counterDetails, id: \.self) { detail in
                    DetailRow(detail: detail)
                }
                .onDelete { indices in
                    self.counterDetails.delete(at: indices, from: self.viewContext)
                }

                HStack {
                    TextField("Enter a counter name", text: $newText, onCommit: {
                        self.createDetailCounter()
                    })
                    Button(
                        action: {
                            withAnimation {
                                self.createDetailCounter()
                            }
                        }
                    ) {
                        Image(systemName: "plus")
                    }
                }.padding(CGFloat(self.settings.listPadding))
            }.padding(CGFloat(self.settings.listPadding))
            Spacer()
            Button(action: {
                self.showShareSheet = true
                do {
                    self.csvFileURL = try self.counter.exportToCSV()
                } catch let ex as NSError {
                    self.errorAlertIsPresented = true
                    self.errorText = ex.localizedDescription
                }
            }) {
                HStack {
                    Text("Export to CSV")
                    Image(systemName: "square.and.arrow.up")
                }
                .sheet(isPresented: $showShareSheet, content: {
                    ActivityView(activityItems: [self.csvFileURL!] as [Any], applicationActivities: nil)
                })

                .alert(isPresented: $errorAlertIsPresented, content: {
                    Alert(title: Text("An error has ocurred during CSV-Export"), message: Text(self.errorText))
                })
            }
        }
        .navigationBarTitle(Text(self.counter.wrappedName))
        .navigationBarItems(trailing: EditButton())
    }
}

struct DetailRow: View {
    @ObservedObject var detail: CounterDetail
    @Environment(\.managedObjectContext)
    var viewContext

    // User settings
    @State private var settings = UserSettings()

    var body: some View {
        HStack(alignment: .center) {
            Text("\(detail.wrappedName)").frame(maxWidth: .infinity, alignment: .leading)
            Text("\(detail.count)")
                .fontWeight(.heavy)
                // setting animation to nil will remove a bug where the view could not handle adding 10 quickly (...)
                .frame(alignment: .trailing).padding(.trailing, 10.0).padding(.leading, 10.0).animation(nil)
            // Stepper with all necessary params to count correctly up to 99999
            Stepper(value: $detail.count, in: 0 ... 99999, step: self.settings.stepCount) { Text("") }
        }.padding(CGFloat(self.settings.listPadding))
    }
}
