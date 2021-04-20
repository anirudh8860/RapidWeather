//
//  RapidWeatherWidget.swift
//  RapidWeatherWidget
//
//  Created by Anirudh Sohil on 19/04/21.
//

import WidgetKit
import SwiftUI
import Intents

struct Provider: IntentTimelineProvider {
    var widgetLocationManager = WidgetLocationManager()

    
    func placeholder(in context: Context) -> RapidWeatherDataEntry {
        RapidWeatherDataEntry(date: Date(), configuration: ConfigurationIntent(), location: "Cannot fetch data at this time", temperature: "", condition: "", isDay: 1, icon: Image("113"))
    }

    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (RapidWeatherDataEntry) -> ()) {
        let entry = RapidWeatherDataEntry(date: Date(), configuration: configuration, location: "San Francisco", temperature: "30°C", condition: "Sunny", isDay: 1, icon: Image("113"))
        completion(entry)
    }

    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [RapidWeatherDataEntry] = []
        var currLocation: String!
        let currentDate = Date()
        let minuteOffset = 5
        
        widgetLocationManager.fetchLocation { (location) in
            currLocation = "\(location.coordinate.latitude),\(location.coordinate.longitude)"
            RapidWeatherClient.getCurrentWeather(location: currLocation) {
                (currentWeather, error) in
                var location, temperature, condition, icon: String!
                var isDay: Int = 1
                
                if let error = error {
                    location = "Cannot fetch data at this time due to: \(error.localizedDescription)"
                    temperature = ""
                    condition = ""
                } else {
                    location = currentWeather?.location.name
                    
                    let tempKey = "Temperature Format"
                    let defaults = UserDefaults(suiteName: "group.RapidWeatherUserDefaults")
                    if (defaults?.string(forKey: tempKey) == "Celsius") {
                        temperature = "\(currentWeather?.current.tempC ?? 0)°C"
                    } else {
                        temperature = "\(currentWeather?.current.tempF ?? 0)°F"
                    }
                    
                    condition = currentWeather?.current.condition.text
                    
                    isDay = (currentWeather?.current.isDay)!
                    
                    icon = currentWeather?.current.condition.icon
                }
                
                let nextUpdate = Calendar.current.date(byAdding: .minute, value: minuteOffset, to: currentDate)!
                let entry = RapidWeatherDataEntry(
                                        date: currentDate,
                                        configuration: configuration,
                                        location: location,
                                        temperature: temperature,
                                        condition: condition,
                                        isDay: isDay,icon: Image(getWeatherCode(icon: icon, isDay: isDay)))
                entries.append(entry)
                let timeline = Timeline(entries: entries, policy: .after(nextUpdate))
                completion(timeline)
            }
        }

    }
}

struct RapidWeatherDataEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationIntent
    let location: String
    let temperature: String
    let condition: String
    let isDay: Int
    let icon: Image
}

struct RapidWeatherWidgetEntryView : View {
    @Environment(\.widgetFamily) var family
    var entry: Provider.Entry
    
    var dayGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(
                colors:
                [
                    Color(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0),
                    Color(red: 53.0/255.0, green: 163.0/255.0, blue: 255.0/255.0)
                ]),
            startPoint: .top,
            endPoint: .bottom)
    }
    
    var nightGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(
                colors:
                [
                    Color(red: 10.0/255.0, green: 39.0/255.0, blue: 122.0/255.0),
                    Color(red: 2.0/255.0, green: 14.0/255.0, blue: 49.0/255.0)
                ]),
            startPoint: .top,
            endPoint: .bottom)
    }

    
    var body: some View {
        let fontColor = entry.isDay == 1 ? Color.black : Color.white
        
        VStack {
            Text(entry.location)
                .font(.body)
                .bold()
                .foregroundColor(fontColor)
            
            Text(entry.condition)
                .font(.caption)
                .foregroundColor(fontColor)
                .padding(.bottom, /*@START_MENU_TOKEN@*/10/*@END_MENU_TOKEN@*/)
            
            entry.icon
                .aspectRatio(contentMode: .fit)
                .frame(width: 30, height: 30, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
            
            
            Text(entry.temperature)
                .font(.system(size: 30))
                .foregroundColor(fontColor)
                
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .edgesIgnoringSafeArea(.all)
        .background((entry.isDay == 1 ? dayGradient: nightGradient))
        
    }
}

func getWeatherCode(icon: String, isDay: Int) -> String {
    var op = icon.suffix(7)
    op = op.prefix(3)
    return isDay == 1 ? String(op): "\(String(op))-1"
}

@main
struct RapidWeatherWidget: Widget {
    let kind: String = "RapidWeatherWidget"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
            RapidWeatherWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Rapid Weather")
        .description("This shows you the weather of your location quickly")
        .supportedFamilies([.systemSmall])
    }
}


struct RapidWeatherWidget_Previews: PreviewProvider {
    static var previews: some View {
        RapidWeatherWidgetEntryView(entry: RapidWeatherDataEntry(date: Date(), configuration: ConfigurationIntent(), location: "San Francisco", temperature: "30°C", condition: "Sunny", isDay: 1, icon: Image("113")))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
