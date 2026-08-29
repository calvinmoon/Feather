//
//  AboutView.swift
//  Feather
//
//  Created by samara on 30.04.2025.
//

import SwiftUI
import NimbleViews
import NimbleJSON

// MARK: - Extension: Model
extension AboutView {
	struct GithubRelease: Decodable {
		let tagName: String
		let htmlUrl: URL

		private enum CodingKeys: String, CodingKey {
			case tagName = "tag_name"
			case htmlUrl = "html_url"
		}
	}
}

// MARK: - View
struct AboutView: View {
	private let _dataService = NBFetchService()
	private let _releasesApiUrl = "https://api.github.com/repos/calvinmoon/Featherwright/releases/latest"

	@State private var _latestFeatherRelease: GithubRelease?

	// MARK: Body
	var body: some View {
		NBList(.localized("About")) {
			Section {
				VStack {
					FRAppIconView(size: 72)
					
					Text(Bundle.main.name)
						.font(.largeTitle)
						.bold()
						.foregroundStyle(Color.accentColor)
					
					HStack(spacing: 4) {
						Text(.localized("Version"))
						Text(Bundle.main.version)
					}
					.font(.footnote)
					.foregroundStyle(.secondary)

					if let release = _latestFeatherRelease {
						Button {
							UIApplication.open(release.htmlUrl)
						} label: {
							HStack(spacing: 4) {
								Image(systemName: "arrow.down.circle.fill")
								Text(verbatim: .localized("Update Available: %@", arguments: release.tagName))
							}
							.font(.footnote)
						}
						.padding(.top, 2)
					}
				}
			}
			.frame(maxWidth: .infinity)
			.listRowBackground(EmptyView())
		}
		.onAppear(perform: _checkForUpdates)
	}
}

// MARK: - Extension: update check
extension AboutView {
	private func _checkForUpdates() {
		_dataService.fetch(from: _releasesApiUrl) { (result: Result<GithubRelease, Error>) in
			guard
				case .success(let release) = result,
				_isVersion(release.tagName, newerThan: Bundle.main.version)
			else {
				return
			}

			DispatchQueue.main.async {
				_latestFeatherRelease = release
			}
		}
	}

	private func _isVersion(_ remote: String, newerThan local: String) -> Bool {
		let remoteVersion = remote.hasPrefix("v") ? String(remote.dropFirst()) : remote
		return remoteVersion.compare(local, options: .numeric) == .orderedDescending
	}
}
