//
//  SceneDelegate.swift
//  Feather
//
//  Created by samsam on 5/25/26.
//

import UIKit
import struct SwiftUI.Color

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
	var window: UIWindow?

	func scene(
		_ scene: UIScene,
		willConnectTo session: UISceneSession,
		options connectionOptions: UIScene.ConnectionOptions
	) {
		guard let windowScene = scene as? UIWindowScene else { return }
		
		let window = UIWindow(windowScene: windowScene)
		let controller = TabBarController()
		window.rootViewController = controller
		
		window.tintColor = UIColor(
			Color(
				hex: UserDefaults.standard.string(forKey: "Feather.userTintColor") 
				?? "#848ef9"
			)
		)
		window.overrideUserInterfaceStyle = UIUserInterfaceStyle(
			rawValue: UserDefaults.standard.integer(forKey: "Feather.userInterfaceStyle")
		) ?? .unspecified
		
		window.makeKeyAndVisible()
		
		self.window = window
	}
}
