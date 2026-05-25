//
//  AppearanceViewController.swift
//  Feather
//
//  Created by samsam on 5/24/26.
//
import UIKit

private struct _Icon: Identifiable {
	var displayName: String
	var key: String?
	var image: UIImage
	var id: String { key ?? displayName }
	
	init(displayName: String,key: String? = nil) {
		self.displayName = displayName
		self.key = key
		self.image = _altImage(key)
	}
}

fileprivate func _altImage(_ name: String?) -> UIImage {
	let path = Bundle.main.bundleURL.appendingPathComponent((name ?? "AppIcon60x60") + "@2x.png")
	return UIImage(contentsOfFile: path.path) ?? UIImage()
}

final class AppearanceViewController: ThemedTableViewController {
	var currentIcon: String? = UIApplication.shared.alternateIconName
	
	private var icons: [_Icon] = [
		.init(displayName: "Current", key: nil),
		.init(displayName: "Pinky", key: "V2Mac"),
		.init(displayName: "Classic", key: "V0"),
		.init(displayName: "Donator", key: "Donor"),
		.init(displayName: "Wing", key: "Wing"),
	]
	
	override func viewDidLoad() {
		super.viewDidLoad()
		title = "Appearance"
	}
}

// MARK: - Table
extension AppearanceViewController {
	override func numberOfSections(in tableView: UITableView) -> Int { 2 }
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		section == 0 ? 2 : icons.count
	}
	
	override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		section == 1 ? "Icons" : nil
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
		var content = cell.defaultContentConfiguration()
		
		cell.accessoryView = nil
		cell.accessoryType = .none
		
		if indexPath.section == 0 {
			if indexPath.row == 0 {
				content.text = "Appearance"

				let styles = UIUserInterfaceStyle.allCases
				let segmented = UISegmentedControl(items: styles.map { $0.label })

				let raw = UserDefaults.standard.integer(forKey: "Feather.userInterfaceStyle")
				let current = UIUserInterfaceStyle(rawValue: raw) ?? .unspecified

				segmented.selectedSegmentIndex = styles.firstIndex(of: current) ?? 0
				segmented.addTarget(self, action: #selector(_didChangeStyle(_:)), for: .valueChanged)

				cell.accessoryView = segmented
			} else {
				content.text = "Tint Color"
				cell.accessoryType = .disclosureIndicator
			}
		} else {
			let icon = icons[indexPath.row]
			content.text = icon.displayName
			content.image = icon.image
			content.imageProperties.maximumSize = CGSize(width: 45, height: 45)
			content.imageProperties.cornerRadius = 10
			cell.accessoryType = (icon.key == currentIcon) ? .checkmark : .none
		}
		
		cell.contentConfiguration = content
		return cell
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		
		tableView.deselectRow(at: indexPath, animated: true)
		
		if indexPath.section == 0 && indexPath.row == 1 {
			_openColorWheel()
			return
		}
		
		guard indexPath.section == 1 else { return }
		
		let icon = icons[indexPath.row]
		
		UIApplication.shared.setAlternateIconName(icon.key) { _ in
			DispatchQueue.main.async {
				self.currentIcon = UIApplication.shared.alternateIconName
				tableView.reloadSections(IndexSet(integer: 1), with: .automatic)
			}
		}
	}
}

extension AppearanceViewController {
	@objc private func _didChangeStyle(_ sender: UISegmentedControl) {
		let map: [UIUserInterfaceStyle] = [.unspecified, .light, .dark]
		let style = map[sender.selectedSegmentIndex]
		
		UserDefaults.standard.set(style.rawValue, forKey: "Feather.userInterfaceStyle")
		view.window?.overrideUserInterfaceStyle = style
	}
	
	@objc private func _openColorWheel() {
		let vc = UIColorPickerViewController()
		
		if 
			let data = UserDefaults.standard.data(forKey: "Feather.userTintColor"),
			let color = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: data) 
		{
			vc.selectedColor = color
		}
		
		vc.delegate = self
		present(vc, animated: true)
	}
}

extension AppearanceViewController: UIColorPickerViewControllerDelegate {
	func colorPickerViewController(
		_ viewController: UIColorPickerViewController,
		didSelect color: UIColor,
		continuously: Bool
	) {
		if let data = try? NSKeyedArchiver.archivedData(withRootObject: color, requiringSecureCoding: false) {
			UserDefaults.standard.set(data, forKey: "Feather.userTintColor")
		}
		
		view.window?.tintColor = color
		view.tintColor = color
	}
}
