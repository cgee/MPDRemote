// TracksListTableView.swift
// Copyright (c) 2017 Nyx0uf
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.


import UIKit


final class TracksListTableView : UITableView
{
	// MARK: - Public properties
	// Tracks list
	var tracks = [Track]()
	{
		didSet
		{
			DispatchQueue.main.async {
				self.reloadData()
			}
		}
	}
	// Should add a dummy cell at the end
	var useDummy = false

	override init(frame: CGRect, style: UITableViewStyle)
	{
		super.init(frame: frame, style: style)

		self.dataSource = self
		self.register(TrackTableViewCell.classForCoder(), forCellReuseIdentifier: "fr.whine.mpdremote.cell.track")
		self.separatorStyle = .none
		self.backgroundColor = #colorLiteral(red: 0.921431005, green: 0.9214526415, blue: 0.9214410186, alpha: 1)
		self.rowHeight = 44.0

		NotificationCenter.default.addObserver(self, selector: #selector(playingTrackChangedNotification(_:)), name: .playingTrackChanged, object: nil)
	}

	required init?(coder aDecoder: NSCoder)
	{
		super.init(coder: aDecoder)

		self.dataSource = self
		self.register(TrackTableViewCell.classForCoder(), forCellReuseIdentifier: "fr.whine.mpdremote.cell.track")
		self.separatorStyle = .none
		self.backgroundColor = #colorLiteral(red: 0.921431005, green: 0.9214526415, blue: 0.9214410186, alpha: 1)
		self.rowHeight = 44.0

		NotificationCenter.default.addObserver(self, selector: #selector(playingTrackChangedNotification(_:)), name: .playingTrackChanged, object: nil)
	}

	deinit
	{
		NotificationCenter.default.removeObserver(self)
	}

	// MARK: - Private
	func playingTrackChangedNotification(_ notification: Notification)
	{
		self.reloadData()
	}
}

// MARK: - UITableViewDataSource
extension TracksListTableView : UITableViewDataSource
{
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		return useDummy ? tracks.count + 1 : tracks.count
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
	{
		let cell = tableView.dequeueReusableCell(withIdentifier: "fr.whine.mpdremote.cell.track", for: indexPath) as! TrackTableViewCell
		cell.backgroundColor = #colorLiteral(red: 0.921431005, green: 0.9214526415, blue: 0.9214410186, alpha: 1)
		cell.contentView.backgroundColor = cell.backgroundColor
		cell.lblTitle.backgroundColor = cell.backgroundColor
		cell.lblTrack.backgroundColor = cell.backgroundColor
		cell.lblDuration.backgroundColor = cell.backgroundColor

		// Dummy to let some space for the mini player
		if indexPath.row == tracks.count
		{
			cell.lblTitle.text = ""
			cell.lblTrack.text = ""
			cell.lblDuration.text = ""
			cell.separator.isHidden = true
			cell.selectionStyle = .none
			return cell
		}

		cell.separator.isHidden = false
		cell.lblTitle.textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
		cell.lblTrack.textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
		cell.lblDuration.textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)

		let track = tracks[indexPath.row]
		cell.lblTrack.text = String(track.trackNumber)
		cell.lblTitle.text = track.name
		let minutes = track.duration.minutesRepresentation().minutes
		let seconds = track.duration.minutesRepresentation().seconds
		cell.lblDuration.text = "\(minutes):\(seconds < 10 ? "0" : "")\(seconds)"

		if PlayerController.shared.currentTrack == track
		{
			cell.lblTrack.font = UIFont(name: "HelveticaNeue-Bold", size: 10)
			cell.lblTitle.font = UIFont(name: "HelveticaNeue-CondensedBlack", size: 14)
			cell.lblDuration.font = UIFont(name: "HelveticaNeue-Medium", size: 10)
		}
		else
		{
			cell.lblTrack.font = UIFont(name: "HelveticaNeue", size: 10)
			cell.lblTitle.font = UIFont(name: "HelveticaNeue-Medium", size: 14)
			cell.lblDuration.font = UIFont(name: "HelveticaNeue-Light", size: 10)
		}

		// Accessibility
		var stra = "\(NYXLocalizedString("lbl_track")) \(track.trackNumber), \(track.name)\n"
		if minutes > 0
		{
			stra += "\(minutes) \(minutes == 1 ? NYXLocalizedString("lbl_minute") : NYXLocalizedString("lbl_minutes")) "
		}
		if seconds > 0
		{
			stra += "\(seconds) \(seconds == 1 ? NYXLocalizedString("lbl_second") : NYXLocalizedString("lbl_seconds"))"
		}
		cell.accessibilityLabel = stra

		return cell
	}
}
