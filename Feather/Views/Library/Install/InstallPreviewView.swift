//
//  InstallPreview.swift
//  Feather
//
//  Created by samara on 22.04.2025.
//

import SwiftUI
import NimbleViews
import IDeviceSwift
import OSLog

// MARK: - View
struct InstallPreviewView: View {
	@Environment(\.dismiss) var dismiss

	@AppStorage("Feather.useShareSheetForArchiving") private var _useShareSheet: Bool = false
	@AppStorage("Feather.installationMethod") private var _installationMethod: Int = 0
	@AppStorage("Feather.serverMethod") private var _serverMethod: Int = 0
	@State private var _isWebviewPresenting = false
	@State private var progressTask: Task<Void, Never>?
	@State private var _installTask: Task<Void, Never>?
	
	var app: AppInfoPresentable
	@StateObject var viewModel: InstallerStatusViewModel
	@StateObject var installer: ServerInstaller
	
	@State var isSharing: Bool
	
	private let _installingBundleIdentifier: String?

	init(app: AppInfoPresentable, isSharing: Bool = false) {
		self.app = app
		self.isSharing = isSharing
		self._installingBundleIdentifier = app.identifier
		let viewModel = InstallerStatusViewModel(isIdevice: UserDefaults.standard.integer(forKey: "Feather.installationMethod") == 1)
		self._viewModel = StateObject(wrappedValue: viewModel)
		self._installer = StateObject(wrappedValue: try! ServerInstaller(app: app, viewModel: viewModel))
	}
	
	// MARK: Body
	var body: some View {
		let cornerRadius = {
			if #available(iOS 26.0, *) {
				28.0
			} else {
				10.5
			}
		}()
		
		ZStack {
			InstallProgressView(app: app, viewModel: viewModel)
			_status()
			_button()
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
		.background(Color(UIColor.secondarySystemBackground))
		.cornerRadius(cornerRadius)
		.padding()
		.sheet(isPresented: $_isWebviewPresenting) {
			SafariRepresentableView(url: installer.pageEndpoint).ignoresSafeArea()
		}
		.onReceive(viewModel.$status) { newStatus in
			if case .completed(.success()) = newStatus, _shouldDeleteSignedAppAfterInstall {
				Storage.shared.deleteApp(for: app)
			}

			if _installationMethod == 0 {
				if case .ready = newStatus {
					if _serverMethod == 0 {
						UIApplication.shared.open(URL(string: installer.iTunesLink)!)
					} else if _serverMethod == 1 {
						_isWebviewPresenting = true
					}
				}
				
				if case .sendingPayload = newStatus, _serverMethod == 1 {
					_isWebviewPresenting = false
				}
				
				if case .installing = newStatus {
					if progressTask == nil {
						progressTask = startInstallProgressPolling(
							bundleID: app.identifier!,
							viewModel: viewModel
						)
					}
				}
				
				switch newStatus {
				case .completed, .broken(_):
					progressTask?.cancel()
					progressTask = nil
					#if !targetEnvironment(macCatalyst)
					BackgroundAudioManager.shared.stop()
					#endif
				default:
					break
				}
			}
		}
		.onAppear(perform: _install)
		
		#if !targetEnvironment(macCatalyst)
		.onAppear {
			BackgroundAudioManager.shared.start()
		}
		#endif
		
		.onDisappear {
			// Dismissing the pane stops the underlying installation as best
			// as we can: cancel the orchestration task and shut the local
			// server down so an in-flight device transfer is cut off.
			_installTask?.cancel()
			_installTask = nil
			progressTask?.cancel()
			progressTask = nil
			installer.stop()
			
			#if !targetEnvironment(macCatalyst)
			BackgroundAudioManager.shared.stop()
			#endif
		}
	}
	
	@ViewBuilder
	private func _status() -> some View {
		Label(viewModel.statusLabel, systemImage: viewModel.statusImage)
			.padding()
			.labelStyle(.titleAndIcon)
			.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
			.animation(.smooth, value: viewModel.statusImage)
	}
	
	@ViewBuilder
	private func _button() -> some View {
		ZStack {
			if viewModel.isCompleted {
				Button {
					UIApplication.openApp(with: _installingBundleIdentifier ?? "")
				} label: {
					NBButton("Open", systemImage: "", style: .text)
				}
				.padding()
				.compatTransition()
			}
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
		.animation(.easeInOut(duration: 0.3), value: viewModel.isCompleted)
	}
	
	private func _install() {
		guard isSharing || app.identifier != Bundle.main.bundleIdentifier! || _installationMethod == 1 else {
			UIAlertController.showAlertWithOk(
				title: .localized("Install"),
				message: .localized("You cannot update ‘%@‘ with itself, please use an alternative tool to update it.", arguments: Bundle.main.name)
			)
			return
		}
				
		_installTask = Task.detached {
			do {
				let handler = await ArchiveHandler(app: app, viewModel: viewModel)
				try await handler.move()
				
				let packageUrl = try await handler.archive()

				// The pane may have been dismissed while packaging; bail out before
				// anything is offered to the device.
				try Task.checkCancellation()
				if await !isSharing {
					if await _installationMethod == 0 {
						await MainActor.run {
							installer.packageUrl = packageUrl
							viewModel.status = .ready
						}
						
						if case .installing = await viewModel.status {
							let task = await startInstallProgressPolling(
								bundleID: app.identifier!,
								viewModel: viewModel
							)

							await MainActor.run {
								progressTask = task
							}
						}
					} else if await _installationMethod == 1 {
						let handler = await InstallationProxy(viewModel: viewModel)
						let isSelf = app.identifier == Bundle.main.bundleIdentifier!
						// InstallationProxy cancels its inner operation (upload and
						// connection setup) when the surrounding task is cancelled.
						try await handler.install(at: packageUrl, suspend: isSelf)
					}
				} else {
					let package = try await handler.moveToArchive(packageUrl, shouldOpen: !_useShareSheet)
					
					if await !_useShareSheet {
						await MainActor.run {
							dismiss()
						}
					} else {
						if let package {
							await MainActor.run {
								dismiss()
								UIActivityViewController.show(activityItems: [package])
							}
						}
					}
				}
			} catch is CancellationError {
				// The pane was dismissed mid-install; the operation was
				// stopped as best as we could, nothing to report.
			} catch is VPNUnreachableError {
				await progressTask?.cancel()

				await MainActor.run {
					_presentVPNUnreachableAlert()
				}
			} catch {
				Logger.misc.error("Install failed: \(String(describing: error))")
				await progressTask?.cancel()

				await MainActor.run {
					UIAlertController.showAlertWithOk(
						title: .localized("Install"),
						message: String(describing: error),
						action: {
							HeartbeatManager.shared.start(true)
							dismiss()
						}
					)
				}
			}
		}
	}

	private func _presentVPNUnreachableAlert() {
		let localDevVpnUrl = URL(string: "localdevvpn://")
		let isLocalDevVpnAvailable = localDevVpnUrl.map { UIApplication.shared.canOpenURL($0) } ?? false

		let primaryAction: UIAlertAction
		if isLocalDevVpnAvailable {
			primaryAction = UIAlertAction(title: .localized("Enable VPN"), style: .default) { _ in
				guard let enableUrl = URL(string: "localdevvpn://enable?scheme=feather") else { return }
				// A process already running before LocalDevVPN's tunnel comes up can keep a
				// stale NECP routing policy for up to about a minute, blocking its own
				// traffic through the new tunnel even though the interface is up — only a
				// fresh process launch is guaranteed to pick up the current policy right
				// away. So once the handoff to LocalDevVPN is confirmed, quit outright; the
				// user reopens Feather into a clean process instead of waiting it out.
				UIApplication.shared.open(enableUrl, options: [:]) { _ in
					CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication)
					exit(0)
				}
			}
		} else {
			primaryAction = UIAlertAction(title: .localized("Download LocalDevVPN"), style: .default) { _ in
				UIApplication.open("https://apps.apple.com/us/app/localdevvpn/id6755608044")
				dismiss()
			}
		}

		let cancelAction = UIAlertAction(title: .localized("Cancel"), style: .cancel) { _ in
			dismiss()
		}

		UIAlertController.showAlert(
			title: .localized("Cannot Reach Device"),
			message: .localized("Feather couldn't connect to your device. Make sure LocalDevVPN is running, then try installing again."),
			actions: [primaryAction, cancelAction]
		)
	}

	private func startInstallProgressPolling(
		bundleID: String,
		viewModel: InstallerStatusViewModel
	) -> Task<Void, Never> {

		Task.detached(priority: .background) {
			var hasStarted = false

			while !Task.isCancelled {
				let rawProgress = await UIApplication.installProgress(for: bundleID) ?? 0.0

				if rawProgress > 0 {
					hasStarted = true
				}

				let progress = await hasStarted
					? _normalizeInstallProgress(rawProgress)
					: 0.0

				Logger.misc.info("Install progress for \(bundleID): \(progress)")

				await MainActor.run {
					viewModel.installProgress = progress
				}

				if hasStarted && rawProgress == 0 {
					await MainActor.run {
						viewModel.installProgress = 1.0
						viewModel.status = .completed(.success(()))
					}
					break
				}

				try? await Task.sleep(nanoseconds: 1_000_000) // 1 ms
			}
		}
	}

	private func _normalizeInstallProgress(_ rawProgress: Double) -> Double {
		min(1.0, max(0.0, (rawProgress - 0.6) / 0.3))
	}

	private var _shouldDeleteSignedAppAfterInstall: Bool {
		!isSharing && app.isSigned && OptionsManager.shared.options.post_deleteAppAfterInstalled
	}
}
