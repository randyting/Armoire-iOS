//
//  AMRMainViewController.swift
//  ArmoireApp
//
//  Created by Randy Ting on 10/17/15.
//  Copyright © 2015 Armoire. All rights reserved.
//

import UIKit
import LayerKit

class AMRViewController: UIViewController {
  
  var stylist: AMRUser?
  var client: AMRUser?
 
  func showSettings () {
    let settingsVC = UIAlertController.AMRSettingsController { (setting: AMRSettingsControllerSetting) -> () in
      if setting == AMRSettingsControllerSetting.ProfilePicture {
        PhotoPicker.sharedInstance.selectPhoto(self.stylist, client: self.client, viewDelegate: self, completion: {
          (image: AMRImage) -> () in
          let user = CurrentUser.sharedInstance.user
          user?.profilePhoto = image
          user?.saveInBackground()
        })
      }
    }
    self.presentViewController(settingsVC, animated: true, completion: nil)
  }
}

class AMRMainViewController: AMRViewController, AMRViewControllerProtocol {
  
  @IBOutlet weak var newMessageImageView: UIImageView!
  @IBOutlet weak var newMessageImageViewXConstraint: NSLayoutConstraint!
  
  @IBOutlet weak var menuView: UIView!
  @IBOutlet weak var messagesImageView: UIImageView!
  @IBOutlet weak var notesImageView: UIImageView!
  @IBOutlet weak var calendarImageView: UIImageView!
  @IBOutlet weak var profileIconImageView: UIImageView!
  @IBOutlet weak var containerView: UIView!
  @IBOutlet weak var selectedIconView: UIView!
  
  @IBOutlet weak var selectedIconViewXPositionConstraint: NSLayoutConstraint!
  
  var selectedViewController: UIViewController?
  var layerClient: LYRClient!
  var layerQueryController: LYRQueryController!
  
  //var stylist: AMRUser?
  //var client: AMRUser?
  
  var vcArray: [UINavigationController]!
  var selectedIconImageView: UIImageView?
  var newMessageTapGestureStartPoint: CGFloat!
  var newConversationIdentifier: NSURL!
  
  override func viewDidLoad() {

    super.viewDidLoad()
    subscribeToNotifications()
    setupTabBarAppearance()
    setupNewMessageImageView()
  }
  
  // MARK: - Initial setup
  private func subscribeToNotifications() {
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "onShowMenuView:", name: AMRMainShowMenuView, object: nil)
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "onHideMenuView:", name: AMRMainHideMenuView, object: nil)
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "onUserLogin:", name: kUserDidLoginNotification, object: nil)
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "onUserLogout:", name: kUserDidLogoutNotification, object: nil)
    
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "hideNewMessageImageView", name: kNewMessageIconHidden, object: nil)
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "showNewMessageImageView", name: kNewMessageIconShown, object: nil)
    
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "deviceDidRotate", name: UIDeviceOrientationDidChangeNotification, object: nil)
  }
  
  private func setupLayerQueryController() {
    let query = LYRQuery(queryableClass: LYRConversation.self)
    query.predicate = LYRPredicate(property: "hasUnreadMessages", predicateOperator: LYRPredicateOperator.IsEqualTo, value: true)
    layerQueryController = try? layerClient.queryControllerWithQuery(query, error: ())
    layerQueryController.delegate = self
    layerQueryController.executeWithCompletion { (success: Bool, error: NSError!) -> Void in
      if let error = error {
        print(error.localizedDescription)
      } else {
        print("Query fetched \(self.layerQueryController.numberOfObjectsInSection(0)) message objects")
      }
    }
  }
  
  private func setupNewMessageImageView() {
    newMessageImageView.alpha = 0
    newMessageImageView.image = newMessageImageView.image?.imageWithRenderingMode(.AlwaysTemplate)
    newMessageImageView.clipsToBounds = true
    newMessageImageView.layer.cornerRadius = newMessageImageView.frame.width/2
    newMessageImageView.backgroundColor = UIColor.AMRSecondaryBackgroundColor()
    
    let newMessagePanGR = UIPanGestureRecognizer(target: self, action: "onMessageIconPan:")
    newMessagePanGR.delegate = self
    newMessageImageView.addGestureRecognizer(newMessagePanGR)
    
    let newMessageTapGR = UITapGestureRecognizer(target: self, action: "onMessageIconTap:")
    newMessageImageView.addGestureRecognizer(newMessageTapGR)
    newMessageTapGestureStartPoint = newMessageImageViewXConstraint.constant
    
    hideNewMessageImageView()
  }
  
  func onMessageIconTap(sender: UITapGestureRecognizer) {
    presentConversationWithIdentifier(newConversationIdentifier)
  }
  
  private func presentConversationWithIdentifier(identifier: NSURL) {
    let query = LYRQuery(queryableClass: LYRConversation.self)
    query.predicate = LYRPredicate(property: "identifier", predicateOperator: LYRPredicateOperator.IsEqualTo, value: identifier)
    layerClient.executeQuery(query) { (conversations, error) -> Void in
      if let error = error {
        print(error.localizedDescription)
      } else {
        let nc = UINavigationController(rootViewController: AMRMessagesDetailsViewController(layerClient: self.layerClient))
        let vc = nc.viewControllers.first as! AMRMessagesDetailsViewController
        vc.conversation = conversations.firstObject as! LYRConversation
        let dismissButton = UIBarButtonItem(title: "Dismiss", style: .Plain , target: self, action: "dismissModal:")
        vc.navigationItem.leftBarButtonItem = dismissButton
        self.presentViewController(nc, animated: true, completion: nil)
      }
    }
  }
  
  func dismissModal(sender: UIBarButtonItem) {
    dismissViewControllerAnimated(true) { () -> Void in
      self.hideNewMessageImageView()
    }
  }
  
  func onMessageIconPan(sender: UIPanGestureRecognizer) {
    let state = sender.state
    let translation = sender.translationInView(view)
    
    switch (state) {
    case .Began:
      newMessageTapGestureStartPoint = newMessageImageViewXConstraint.constant
    case .Cancelled:
      break
    case .Changed:
      newMessageImageViewXConstraint.constant = newMessageTapGestureStartPoint - translation.x
    case .Ended:
      if Double(sqrt((translation.x * translation.x) + (translation.y * translation.y) )) > 10.0 {
        hideNewMessageImageView()
      }
    case .Failed:
      break
    case .Possible:
      break
    }
  }
  
  //MARK: - Utility
  func hideNewMessageImageView() {
    UIView.animateWithDuration(1.0, animations: { () -> Void in
      self.newMessageImageView.alpha = 0.0
      }) { (success: Bool) -> Void in
        self.newMessageImageViewXConstraint.constant = self.newMessageTapGestureStartPoint
    }
  }
  
  func showNewMessageImageView() {
    newMessageImageView.alpha = 1.0
    containerView.bringSubviewToFront(newMessageImageView)
  }
  
  // MARK: - Appearance Methods
  private func setupTabBarAppearance() {
    messagesImageView.image = messagesImageView.image?.imageWithRenderingMode(.AlwaysTemplate)
    notesImageView.image = notesImageView.image?.imageWithRenderingMode(.AlwaysTemplate)
    calendarImageView.image = calendarImageView.image?.imageWithRenderingMode(.AlwaysTemplate)
    profileIconImageView.image = profileIconImageView.image?.imageWithRenderingMode(.AlwaysTemplate)
    
    resetIconColors()
    
    selectedIconView.layer.cornerRadius = selectedIconView.frame.width/2
    selectedIconView.backgroundColor = UIColor.AMRPrimaryBackgroundColor()
    
    selectedIconViewXPositionConstraint.constant = 1000
    view.layoutIfNeeded()
    
    menuView.backgroundColor = UIColor.AMRSecondaryBackgroundColor()
  }
  
  private func resetIconColors() {
    messagesImageView.tintColor = UIColor.AMRUnselectedTabBarButtonTintColor()
    notesImageView.tintColor = UIColor.AMRUnselectedTabBarButtonTintColor()
    calendarImageView.tintColor = UIColor.AMRUnselectedTabBarButtonTintColor()
    profileIconImageView.tintColor = UIColor.AMRUnselectedTabBarButtonTintColor()
  }
  
  private func setSelectedAppearanceColorForImageView(imageView: UIImageView) {
    selectedIconImageView = imageView
    
    UIView.animateWithDuration(0.5) { () -> Void in
      self.resetIconColors()
      self.selectedIconViewXPositionConstraint.constant = imageView.center.x - self.selectedIconView.frame.width/2
      imageView.tintColor = UIColor.AMRSelectedTabBarButtonTintColor()
      self.menuView.layoutIfNeeded()
    }
  }
  
  func deviceDidRotate() {
    if let selectedIconImageView = selectedIconImageView {
      dispatch_async(dispatch_get_main_queue(), { () -> Void in
        self.selectedIconViewXPositionConstraint.constant = selectedIconImageView.center.x - self.selectedIconView.frame.width/2
      })
    }
  }
  
  func onShowMenuView(notification: NSNotification) {
    menuView.hidden = false
  }
  
  func onHideMenuView(notification: NSNotification) {
    menuView.hidden = true
  }
  
  // MARK: - Settings Icon
  func onTapSettings(notification: NSNotification){
    //let settingsVC = AMRSettingsViewController()
    self.showSettings()
  }
  
  // MARK: - Notifiation Observers
  func onUserLogin(notification: NSNotification){
    setVcData(nil, client: nil)
    if (self.client != nil) {
      //client workflow
      let vc = AMRClientsDetailViewController(layerClient: layerClient)
      vc.setVcData(self.stylist, client: self.client)
      UIApplication.sharedApplication().windows[0].rootViewController = vc
      UIApplication.sharedApplication().windows[0].makeKeyAndVisible()
    } else {
      //stylist workflow
      selectViewController(vcArray[1])
      setSelectedAppearanceColorForImageView(profileIconImageView)
      setupLayerQueryController()
      newMessageImageView.alpha = 0
    }
  }
  
  func onUserLogout(notification: NSNotification){
    self.client = nil
    self.stylist = nil
    flushVcArray()
    self.dismissViewControllerAnimated(true, completion: nil)
  }
  
  // MARK: - View Controller Selection
  func selectViewController(viewController: UIViewController){
    if let oldViewController = selectedViewController{
      oldViewController.willMoveToParentViewController(nil)
      oldViewController.view.removeFromSuperview()
      oldViewController.removeFromParentViewController()
    }
    
    self.addChildViewController(viewController)
    viewController.view.frame = self.containerView.bounds
    viewController.view.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
    self.containerView.addSubview(viewController.view)
    viewController.didMoveToParentViewController(self)
    selectedViewController = viewController
  }
  
  internal func flushVcArray() {
    vcArray = nil
  }
  
  internal func setVcData(stylist: AMRUser?, client: AMRUser?) {
    setVcArray()
    setLocalVcData()
    setVcDataForTabs()
  }
  
  private func setVcArray(){
    vcArray = [
      UINavigationController(rootViewController: AMRLoginViewController()),
      UINavigationController(rootViewController: AMRClientsViewController(layerClient: layerClient)),
      UINavigationController(rootViewController: AMRMessagesViewController(layerClient: layerClient) ),
      UINavigationController(rootViewController: AMRNotesViewController()),
      UINavigationController(rootViewController: AMRUpcomingMeetingsViewController()),
      UINavigationController (rootViewController: AMRClientsDetailViewController(layerClient: layerClient))
    ]
  }
  
  private func setVcDataForTabs(){
    for (index, value) in vcArray.enumerate() {
      if (index != 0) {
        let vc = value.viewControllers.first as? AMRViewControllerProtocol
        vc?.setVcData(self.stylist, client: self.client)
      }
    }
  }
  
  private func setLocalVcData(){
    if let user = AMRUser.currentUser(){
      if (user.isStylist){
        self.stylist = user
      } else {
        self.client = user
      }
    }
  }
  
  // MARK: - Tap Icon Actions
  
  @IBAction func onTapMessages(sender: UITapGestureRecognizer) {
    selectViewController(vcArray[2])
    setSelectedAppearanceColorForImageView(sender.view as! UIImageView)
    if newMessageImageView.alpha == 1.0 {
      showNewMessageImageView()
    }
  }
  
  @IBAction func onTapNotes(sender: UITapGestureRecognizer) {
    selectViewController(vcArray[3])
    setSelectedAppearanceColorForImageView(sender.view as! UIImageView)
    if newMessageImageView.alpha == 1.0 {
      showNewMessageImageView()
    }
  }
  
  @IBAction func onTapProfileIcon(sender: UITapGestureRecognizer) {
    selectViewController(vcArray[1])
    setSelectedAppearanceColorForImageView(sender.view as! UIImageView)
    if newMessageImageView.alpha == 1.0 {
      showNewMessageImageView()
    }
  }
  
  @IBAction func onTapCalendar(sender: UITapGestureRecognizer) {
    selectViewController(vcArray[4])
    setSelectedAppearanceColorForImageView(sender.view as! UIImageView)
    if newMessageImageView.alpha == 1.0 {
      showNewMessageImageView()
    }
  }
  
}

protocol AMRViewControllerProtocol {
  func setVcData(stylist: AMRUser?, client: AMRUser?)
}

// MARK: - LYRQueryController Delegate

extension AMRMainViewController: LYRQueryControllerDelegate {
  func queryController(controller: LYRQueryController!, didChangeObject object: AnyObject!, atIndexPath indexPath: NSIndexPath!, forChangeType type: LYRQueryControllerChangeType, newIndexPath: NSIndexPath!) {
    
    if type != LYRQueryControllerChangeType.Delete && controller.numberOfObjectsInSection(0) > 0{
      let conversation = object as! LYRConversation
      newConversationIdentifier = conversation.identifier
      var remainingParticipants = conversation.participants
      remainingParticipants.remove(AMRUser.currentUser()!.objectId!)
      let senderObjectID = remainingParticipants.first as! String

      AMRUserManager.sharedManager.queryForUserWithObjectID(senderObjectID) { (users: NSArray?, error: NSError?) -> Void in
        if let error = error {
          print(error.localizedDescription)
        } else {
          let user = users!.firstObject! as! AMRUser
          if let profileImage = user.profilePhoto {
            self.newMessageImageView.setAMRImage(profileImage, withPlaceholder: "messaging")
          } else {
            self.newMessageImageView.setAMRImage(nil, withPlaceholder: "messaging")
          }
          self.showNewMessageImageView()
        }
        
      }

    }
  }
}

// MARK: - UIGestureRecognizer Delegate

extension AMRMainViewController: UIGestureRecognizerDelegate {
  func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
    return true
  }
}
