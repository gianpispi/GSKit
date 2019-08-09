//
//  HUD.swift
//  GSKit
//
//  Created by Gianpiero Spinelli on 09/08/2019.
//  Copyright © 2019 GS. All rights reserved.
//

import UIKit

//https://github.com/Swiftify-Corp/IHProgressHUD/blob/master/IHProgressHUD/Classes/IHProgressHUD.swift

private class HUDViewController: UIViewController {
    private var hudView: UIVisualEffectView?
    private var backHudView: UIView = UIView()
    private var cornerRadius: CGFloat = 14
    
    private var statusLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        //        l.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        l.font = UIFont.preferredFont(forTextStyle: .body)
        l.minimumScaleFactor = 0.6
        l.textColor = .black
        l.textAlignment = .center
        return l
    }()
    
    //    @available(iOS 10.0, *)
    //    private var hapticGenerator: UINotificationFeedbackGenerator? {
    //        get {
    //            return UINotificationFeedbackGenerator()
    //        }
    //    }
    
    internal override func viewDidLoad() {
        super.viewDidLoad()
        
        view.isUserInteractionEnabled = false
        view.backgroundColor = UIColor.clear
        view.accessibilityIdentifier = "Loading HUD"
        isAccessibilityElement = true
        
        createHudView()
    }
    
    private func createHudView() {
        backHudView.backgroundColor = .clear
        backHudView.layer.cornerRadius = cornerRadius
        backHudView.layer.masksToBounds = true
        backHudView.translatesAutoresizingMaskIntoConstraints = false
        
        let effect = UIBlurEffect(style: .light)
        self.hudView = UIVisualEffectView(effect: effect)
        
        if let hudView = hudView {
            hudView.translatesAutoresizingMaskIntoConstraints = false
            
            let activityIndicatorView = UIView()
            activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
            activityIndicatorView.backgroundColor = .clear
            hudView.contentView.addSubview(activityIndicatorView)
            
            let activityIndicator = UIActivityIndicatorView(style: .whiteLarge)
            activityIndicator.frame.origin = CGPoint(x: 0, y: 0)
            activityIndicator.translatesAutoresizingMaskIntoConstraints = false
            activityIndicator.color = .black
            activityIndicator.startAnimating()
            activityIndicatorView.addSubview(activityIndicator)
            
            hudView.contentView.addSubview(statusLabel)
            
            NSLayoutConstraint.activate([
                statusLabel.bottomAnchor.constraint(equalTo: hudView.bottomAnchor, constant: -15),
                statusLabel.leadingAnchor.constraint(equalTo: hudView.leadingAnchor, constant: 10),
                statusLabel.trailingAnchor.constraint(equalTo: hudView.trailingAnchor, constant: -10),
                statusLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 0),
                
                activityIndicator.centerYAnchor.constraint(equalTo: activityIndicatorView.centerYAnchor),
                activityIndicator.centerXAnchor.constraint(equalTo: activityIndicatorView.centerXAnchor),
                
                activityIndicatorView.topAnchor.constraint(equalTo: hudView.topAnchor, constant: 15),
                activityIndicatorView.bottomAnchor.constraint(equalTo: statusLabel.topAnchor, constant: 0),
                activityIndicatorView.leadingAnchor.constraint(equalTo: hudView.leadingAnchor, constant: 10),
                activityIndicatorView.trailingAnchor.constraint(equalTo: hudView.trailingAnchor, constant: -10),
                ])
            
            backHudView.addSubview(hudView)
            hudView.fillSuperview()
            
            DispatchQueue.main.async {
                self.view.addSubview(self.backHudView)
                
                #if os(tvOS)
                self.backHudView.widthAnchor.constraint(greaterThanOrEqualTo: self.view.widthAnchor, multiplier: 0.11).isActive = true
                #else
                self.backHudView.widthAnchor.constraint(greaterThanOrEqualTo: self.view.widthAnchor, multiplier: 0.3).isActive = true
                #endif
                
                self.backHudView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
                self.backHudView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
                self.backHudView.heightAnchor.constraint(equalTo: self.backHudView.widthAnchor, multiplier: 1).isActive = true
            }
        }
    }
    
    func setText(_ text: String) {
        self.statusLabel.text = text
    }
}

public class GSHud {
    fileprivate var hudWindow: UIWindow? = nil
    private var numberOfActivities: Int = 0
    
    /// - `MKProgress` shared instance
    public static var shared = GSHud()
    
    /// Creating `UIWindow` to present Progress HUD
    /// 'MKProgressViewController' initialization and settting as rootViewController for the window.
    /// Returns 'UIWindow'.
    fileprivate func getHUDWindow() -> UIWindow {
        let hudWindow = UIWindow()
        hudWindow.frame = UIScreen.main.bounds
        hudWindow.isHidden = false
        hudWindow.windowLevel = UIWindow.Level.normal
        hudWindow.backgroundColor = UIColor.clear
        let controller = HUDViewController()
        hudWindow.rootViewController = controller
        return hudWindow
    }
    
    public static func show(withStatus status: String = "") {
        if shared.numberOfActivities == 0 {
            makeKeyWindowVisible(status: status, true)
        }
        
        shared.numberOfActivities += 1
    }
    
    fileprivate static func makeKeyWindowVisible(status: String = "", _ animated: Bool) {
        shared.hudWindow = shared.getHUDWindow()
        
        shared.hudWindow?.makeKeyAndVisible()
        
        if !status.isEmpty {
            guard let rootViewController = shared.hudWindow?.rootViewController as? HUDViewController else { return }
            rootViewController.setText(status)
        }
        
        guard animated else { return }
        shared.playFadeInAnimation()
    }
    
    /// Plays fade in animation
    private func playFadeInAnimation() {
        guard let rootViewController = self.hudWindow?.rootViewController else { return }
        
        rootViewController.view.layer.opacity = 0.0
        
        UIView.animate(withDuration: 0.2, animations: {
            rootViewController.view.layer.opacity = 1.0
        })
    }
    
    private func playFadeOutAnimation(_ completion: ((Bool) -> Void)?) {
        guard let rootViewController = self.hudWindow?.rootViewController else { return }
        
        rootViewController.view.layer.opacity = 1.0
        
        UIView.animate(withDuration: 0.25, animations: {
            rootViewController.view.layer.opacity = 0.0
        }, completion: completion)
    }
    
    /// Hiding the progress hud
    /// - parameter animated: Flag to handle the fadeOut animation on dismiss.
    /// - animated: Default: true
    public static func dismiss(_ animated: Bool = true) {
        func hideProgressHud() {
            shared.hudWindow?.resignKey()
            shared.hudWindow = nil
        }
        
        if shared.numberOfActivities > 0 {
            shared.numberOfActivities -= 1
        }
        
        if shared.numberOfActivities == 0 {
            if animated {
                DispatchQueue.main.async {
                    shared.playFadeOutAnimation({ _ in
                        hideProgressHud()
                    })
                }
            } else {
                hideProgressHud()
            }
        }
    }
    
    public static func dismissNow() {
        shared.numberOfActivities = 0
        dismiss()
    }
}

