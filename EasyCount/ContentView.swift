//
//  ContentView.swift
//  EasyCount
//
//  Created by Zoë Pfister on 03.01.20.
//  Copyright © 2020 Zoë Pfister. All rights reserved.
//

import CoreData
import Foundation
import SwiftUI

private let dateFormatter: DateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .medium
    dateFormatter.timeStyle = .medium
    return dateFormatter
}()

struct ContentView: View {
    @Environment(\.managedObjectContext)
    var viewContext

    @State var isPreferencesPresented = false

    var body: some View {
        NavigationView {
            MasterView()
                .navigationBarTitle(Text("Counters"))
                .navigationBarItems(trailing: Button(
                    action: {
                        self.isPreferencesPresented = true
                    }
                ) {
                    Image(systemName: "gear")
                })
        }
        // Show the Preference View sheet
        .sheet(isPresented: $isPreferencesPresented,
               onDismiss: {
                   self.isPreferencesPresented = false
               },
               content: {
                   PreferenceView()
        })
        .navigationViewStyle(DoubleColumnNavigationViewStyle())
    }
}

struct PreferenceView: View {
    // Actual settings variable
    @ObservedObject var settings = UserSettings()

    var body: some View {
        VStack {
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

struct MasterView: View {
    @Environment(\.managedObjectContext)
    var viewContext

    // User settings
    @State private var settings = UserSettings()

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Counter.timestamp, ascending: true)],
        animation: .default)
    var counters: FetchedResults<Counter>

    @State private var newText: String = ""

    var body: some View {
        List {
            ForEach(counters, id: \.self) { event in
                NavigationLink(
                    destination: DetailView(filter: event)
                ) {
                    VStack(alignment: .leading) {
                        Text("\(event.wrappedName)")
                        Text("\(event.timestamp!, formatter: dateFormatter)")
                            .fontWeight(.light)
                            .font(.system(size: 14))
                    }.padding(CGFloat(self.settings.listPadding))
                }
            }.onDelete { indices in
                self.counters.delete(at: indices, from: self.viewContext)
            }
            HStack {
                TextField("Enter a new counter name", text: $newText)
                Button(
                    action: {
                        withAnimation {
                            if self.newText != "" {
                                Counter.create(in: self.viewContext, with: self.newText)
                                self.newText = ""
                            }
                        }
                    }
                ) {
                    Image(systemName: "plus")
                }
            }.padding(CGFloat(self.settings.listPadding))
        }.padding(CGFloat(self.settings.listPadding))
    }
}

struct DetailView: View {
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
                    TextField("Enter a counter name", text: $newText)
                    Button(
                        action: {
                            withAnimation {
                                if self.newText != "" {
                                    let newCounter = CounterDetail.create(in: self.viewContext)
                                    newCounter.counter = self.counter
                                    newCounter.name = self.newText
                                    self.newText = ""
                                }
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
                .frame(width: .some(CGFloat(60.0)), alignment: .trailing)
            Stepper(value: $detail.count, in: 0 ... 99999, step: 1) { Text("") }
        }.padding(CGFloat(self.settings.listPadding))
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        return ContentView().environment(\.managedObjectContext, context)
    }
}
