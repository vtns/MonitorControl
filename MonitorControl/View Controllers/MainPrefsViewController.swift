//  Copyright © MonitorControl. @JoniVR, @theOneyouseek, @waydabber and others

import Cocoa
import os.log
import Preferences
import ServiceManagement

class MainPrefsViewController: NSViewController, PreferencePane {
  let preferencePaneIdentifier = Preferences.PaneIdentifier.main
  let preferencePaneTitle: String = NSLocalizedString("General", comment: "Shown in the main prefs window")

  var toolbarItemIcon: NSImage {
    if #available(macOS 11.0, *) {
      return NSImage(systemSymbolName: "switch.2", accessibilityDescription: "Display")!
    } else {
      return NSImage(named: NSImage.infoName)!
    }
  }

  let prefs = UserDefaults.standard

  @IBOutlet var startAtLogin: NSButton!
  @IBOutlet var lowerSwAfterBrightness: NSButton!
  @IBOutlet var fallbackSw: NSButton!
  @IBOutlet var showAdvancedDisplays: NSButton!
  @IBOutlet var notEnableDDCDuringStartup: NSButton!
  @IBOutlet var writeDDCOnStartup: NSButton!
  @IBOutlet var readDDCOnStartup: NSButton!

  override func viewDidLoad() {
    super.viewDidLoad()
  }

  @available(macOS, deprecated: 10.10)
  override func viewWillAppear() {
    super.viewWillAppear()
    self.populateSettings()
  }

  @available(macOS, deprecated: 10.10)
  func populateSettings() {
    // This is marked as deprectated but according to the function header it still does not have a replacement as of macOS 12 Monterey and is valid to use.
    let startAtLogin = (SMCopyAllJobDictionaries(kSMDomainUserLaunchd).takeRetainedValue() as? [[String: AnyObject]])?.first { $0["Label"] as? String == "\(Bundle.main.bundleIdentifier!)Helper" }?["OnDemand"] as? Bool ?? false
    self.startAtLogin.state = startAtLogin ? .on : .off
    self.lowerSwAfterBrightness.state = self.prefs.bool(forKey: PrefKey.lowerSwAfterBrightness.rawValue) ? .on : .off
    self.fallbackSw.state = self.prefs.bool(forKey: PrefKey.fallbackSw.rawValue) ? .on : .off
    self.showAdvancedDisplays.state = self.prefs.bool(forKey: PrefKey.showAdvancedDisplays.rawValue) ? .on : .off
    self.notEnableDDCDuringStartup.state = !self.prefs.bool(forKey: PrefKey.enableDDCDuringStartup.rawValue) ? .on : .off
    self.writeDDCOnStartup.state = !self.prefs.bool(forKey: PrefKey.readDDCInsteadOfRestoreValues.rawValue) && self.prefs.bool(forKey: PrefKey.enableDDCDuringStartup.rawValue) ? .on : .off
    self.readDDCOnStartup.state = self.prefs.bool(forKey: PrefKey.readDDCInsteadOfRestoreValues.rawValue) && self.prefs.bool(forKey: PrefKey.enableDDCDuringStartup.rawValue) ? .on : .off
  }

  @IBAction func startAtLoginClicked(_ sender: NSButton) {
    switch sender.state {
    case .on:
      app.setStartAtLogin(enabled: true)
    case .off:
      app.setStartAtLogin(enabled: false)
    default: break
    }
  }

  @IBAction func lowerSwAfterBrightnessClicked(_ sender: NSButton) {
    switch sender.state {
    case .on:
      self.prefs.set(true, forKey: PrefKey.lowerSwAfterBrightness.rawValue)
    case .off:
      self.prefs.set(false, forKey: PrefKey.lowerSwAfterBrightness.rawValue)
      DisplayManager.shared.resetSwBrightnessForAllDisplays()
    default: break
    }
    app.updateDisplaysAndMenus()
  }

  @IBAction func fallbackSwClicked(_ sender: NSButton) {
    switch sender.state {
    case .on:
      self.prefs.set(true, forKey: PrefKey.fallbackSw.rawValue)
    case .off:
      self.prefs.set(false, forKey: PrefKey.fallbackSw.rawValue)
    default: break
    }
    DisplayManager.shared.resetSwBrightnessForAllDisplays()
    app.updateDisplaysAndMenus()
  }

  @IBAction func notEnableDDCDuringStartupClicked(_ sender: NSButton) {
    switch sender.state {
    case .on:
      self.prefs.set(false, forKey: PrefKey.enableDDCDuringStartup.rawValue)
      self.prefs.set(false, forKey: PrefKey.readDDCInsteadOfRestoreValues.rawValue)
      self.writeDDCOnStartup.state = .off
      self.readDDCOnStartup.state = .off
    default: break
    }
  }

  @IBAction func writeDDCOnStartupClicked(_ sender: NSButton) {
    switch sender.state {
    case .on:
      self.prefs.set(false, forKey: PrefKey.readDDCInsteadOfRestoreValues.rawValue)
      self.prefs.set(true, forKey: PrefKey.enableDDCDuringStartup.rawValue)
      self.notEnableDDCDuringStartup.state = .off
      self.readDDCOnStartup.state = .off
    default: break
    }
  }

  @IBAction func readDDCOnStartupClicked(_ sender: NSButton) {
    switch sender.state {
    case .on:
      self.prefs.set(true, forKey: PrefKey.readDDCInsteadOfRestoreValues.rawValue)
      self.prefs.set(true, forKey: PrefKey.enableDDCDuringStartup.rawValue)
      self.notEnableDDCDuringStartup.state = .off
      self.writeDDCOnStartup.state = .off
    default: break
    }
  }

  @IBAction func showAdvancedClicked(_ sender: NSButton) {
    switch sender.state {
    case .on:
      self.prefs.set(true, forKey: PrefKey.showAdvancedDisplays.rawValue)
    case .off:
      self.prefs.set(false, forKey: PrefKey.showAdvancedDisplays.rawValue)
    default: break
    }
    NotificationCenter.default.post(name: Notification.Name(PrefKey.displayListUpdate.rawValue), object: nil)
  }

  @available(macOS, deprecated: 10.10)
  func resetSheetModalHander(modalResponse: NSApplication.ModalResponse) {
    if modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn {
      NotificationCenter.default.post(name: Notification.Name(PrefKey.preferenceReset.rawValue), object: nil)
      self.populateSettings()
    }
  }

  @available(macOS, deprecated: 10.10)
  @IBAction func resetPrefsClicked(_: NSButton) {
    let alert = NSAlert()
    alert.messageText = NSLocalizedString("Reset Preferences?", comment: "Shown in the alert dialog")
    alert.informativeText = NSLocalizedString("Are you sure you want to reset all preferences?", comment: "Shown in the alert dialog")
    alert.addButton(withTitle: NSLocalizedString("Yes", comment: "Shown in the alert dialog"))
    alert.addButton(withTitle: NSLocalizedString("No", comment: "Shown in the alert dialog"))
    alert.alertStyle = NSAlert.Style.warning
    if let window = self.view.window {
      alert.beginSheetModal(for: window, completionHandler: { modalResponse in self.resetSheetModalHander(modalResponse: modalResponse) })
    }
  }
}
