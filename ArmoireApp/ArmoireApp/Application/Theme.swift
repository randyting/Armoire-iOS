//
//  Theme.swift
//  ArmoireApp
//
//  Created by Mathew Kellogg on 11/2/15.
//  Copyright © 2015 Armoire. All rights reserved.
//

import UIKit

enum Theme: Int {
  case Default, Theme1
  
  var mainColor: UIColor {
    switch self {
    case .Default:
      return UIColor(red: 87.0/255.0, green: 188.0/255.0, blue: 95.0/255.0, alpha: 1.0)
    case .Theme1:
      return ColorHelper.sharedInstance.colorFromHexString("#2c3e50")
    }
  }
  
  var mainColorSecondary: UIColor {
    switch self {
    case .Default:
      return UIColor(red: 87.0/255.0, green: 188.0/255.0, blue: 95.0/255.0, alpha: 1.0)
    case .Theme1:
      return ColorHelper.sharedInstance.colorFromHexString("#bdc3c7")
    }
  }
  
  var barStyle: UIBarStyle {
    switch self {
    case .Default:
      return .Default
    case .Theme1:
      //return .Black
      return .Default
    }
  }
  
  var backgroundColor: UIColor {
    switch self {
    case .Default:
      return UIColor(white: 0.9, alpha: 1.0)
    case .Theme1:
      return ColorHelper.sharedInstance.colorFromHexString("#7f8c8d")
    }
  }
  var backgroundColorSecondary: UIColor {
    switch self {
    case .Default:
      return UIColor(white: 0.6, alpha: 1.0)
    case .Theme1:
      return ColorHelper.sharedInstance.colorFromHexString("#34495e")
    }
  }
  
  var highlightColor: UIColor {
    switch self {
    case .Default:
      return UIColor(red: 242.0/255.0, green: 101.0/255.0, blue: 34.0/255.0, alpha: 1.0)
    case .Theme1:
      return ColorHelper.sharedInstance.colorFromHexString("#ecf0f1")
    }
  }
}

let SelectedThemeKey = "SelectedTheme"

struct ThemeManager {
  
  static func currentTheme() -> Theme {
    
    if let storedTheme = NSUserDefaults.standardUserDefaults().valueForKey(SelectedThemeKey)?.integerValue {
      print("Theme: \(Theme(rawValue: storedTheme)!))")
      return Theme(rawValue: storedTheme)!
    } else {
      let thetheme: Theme = .Default
      print("Theme: \(thetheme)")
      return .Default
    }
  }
  
  static func applyTheme(theme: Theme) {
    NSUserDefaults.standardUserDefaults().setValue(theme.rawValue, forKey: SelectedThemeKey)
    NSUserDefaults.standardUserDefaults().synchronize()
    
    let sharedApplication = UIApplication.sharedApplication()
    sharedApplication.delegate?.window??.tintColor = theme.mainColor
    
    UINavigationBar.appearance().barStyle = theme.barStyle
    UINavigationBar.appearance().backgroundColor = theme.backgroundColor
    
    UITabBar.appearance().barStyle = theme.barStyle
    UINavigationBar.appearance().backgroundColor = theme.backgroundColorSecondary
    
    
  }
}


private struct ColorHelper {
  
  static let sharedInstance = ColorHelper()
  
  func colorFromHexString(hexString: String) -> UIColor {
    var rgbValue: UInt32 = 0
    let scanner = NSScanner(string: hexString)
    scanner.scanLocation = 1
    scanner.scanHexInt(&rgbValue)
    return UIColor(
      red: CGFloat((rgbValue >> 16) & 0xff) / 255,
      green: CGFloat((rgbValue >> 08) & 0xff) / 255,
      blue: CGFloat((rgbValue >> 00) & 0xff) / 255,
      alpha: 1.0)
  }
}
