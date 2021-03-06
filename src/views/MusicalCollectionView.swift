// MusicalCollectionView.swift
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


/* Collection view layout */
enum CollectionViewLayoutType : Int
{
	case collection
	case table
}


protocol MusicalCollectionViewDelegate : class
{
	func isSearching(actively: Bool) -> Bool
	func didSelectItem(indexPath: IndexPath)
}

final class TableFlowLayout: UICollectionViewFlowLayout
{
	let itemHeight: CGFloat = 64

	override init()
	{
		super.init()
		setupLayout()
	}

	required init?(coder aDecoder: NSCoder)
	{
		super.init(coder: aDecoder)
		setupLayout()
	}

	func setupLayout()
	{
		minimumInteritemSpacing = 0
		minimumLineSpacing = 1
		scrollDirection = .vertical
	}

	private func itemWidth() -> CGFloat
	{
		return collectionView!.frame.width
	}

	override var itemSize: CGSize
		{
		set
		{
			self.itemSize = CGSize(itemWidth(), itemHeight)
		}
		get
		{
			return CGSize(itemWidth(), itemHeight)
		}
	}

	override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint
	{
		return collectionView!.contentOffset
	}
}

final class CollectionFlowLayout : UICollectionViewFlowLayout
{
	let sideSpan = CGFloat(10.0)
	let columns = 3

	override init()
	{
		super.init()
		setupLayout()
	}

	required init?(coder aDecoder: NSCoder)
	{
		super.init(coder: aDecoder)
		setupLayout()
	}

	func setupLayout()
	{
		self.sectionInset = UIEdgeInsets(top: sideSpan, left: sideSpan, bottom: sideSpan, right: sideSpan)
		scrollDirection = .vertical
	}

	private func itemWidth() -> CGFloat
	{
		return ceil((UIScreen.main.bounds.width / CGFloat(columns)) - (2 * sideSpan))
	}

	override var itemSize: CGSize
		{
		set
		{
			self.itemSize = CGSize(itemWidth(), itemWidth() + 20.0)
		}
		get
		{
			return CGSize(itemWidth(), itemWidth() + 20.0)
		}
	}

	override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint
	{
		return collectionView!.contentOffset
	}
}


final class MusicalCollectionView : UICollectionView
{
	// MARK: - Properties
	// Data sources
	var items = [MusicalEntity]()
	var searchResults = [MusicalEntity]()
	// Type of entities displayd
	var displayType = DisplayType.albums
	// Collection view layout type
	var layoutType = CollectionViewLayoutType.collection
	{
		didSet
		{
			setCollectionLayout(animated: true)
		}
	}
	// Delegate
	weak var myDelegate: MusicalCollectionViewDelegate!
	// Cover download operations
	fileprivate var _downloadOperations = [String : Operation]()

	required init?(coder aDecoder: NSCoder)
	{
		super.init(coder: aDecoder)

		self.dataSource = self
		self.delegate = self
		self.isPrefetchingEnabled = true
		self.prefetchDataSource = self

		let layoutAsTable = UserDefaults.standard.bool(forKey: kNYXPrefCollectionViewLayoutTable)
		self.layoutType = layoutAsTable ? .table : .collection

		self.setCollectionLayout(animated: false)

		NotificationCenter.default.addObserver(self, selector: #selector(collectionViewsLayoutDidChangeNotification(_:)), name: .collectionViewsLayoutDidChange, object: nil)
	}

	// MARK: - Private
	fileprivate func downloadCoverForAlbum(_ album: Album, cropSize: CGSize, callback:((_ cover: UIImage, _ thumbnail: UIImage) -> Void)?) -> CoverOperation
	{
		let key = album.uniqueIdentifier
		if let cop = _downloadOperations[key] as! CoverOperation?
		{
			return cop
		}
		let downloadOperation = CoverOperation(album: album, cropSize: cropSize)
		weak var weakOperation = downloadOperation
		downloadOperation.callback = {(cover: UIImage, thumbnail: UIImage) in
			if let _ = weakOperation
			{
				self._downloadOperations.removeValue(forKey: key)
			}
			if let block = callback
			{
				block(cover, thumbnail)
			}
		}
		_downloadOperations[key] = downloadOperation
		APP_DELEGATE().operationQueue.addOperation(downloadOperation)

		return downloadOperation
	}

	fileprivate func setCollectionLayout(animated: Bool)
	{
		UIView.animate(withDuration: animated ? 0.2 : 0) { () -> Void in
			self.collectionViewLayout.invalidateLayout()

			if self.layoutType == .collection
			{
				self.setCollectionViewLayout(CollectionFlowLayout(), animated: animated)
			}
			else
			{
				self.setCollectionViewLayout(TableFlowLayout(), animated: animated)
			}
		}
	}

	// MARK: - Notifications
	public func collectionViewsLayoutDidChangeNotification(_ notification: Notification)
	{
		let layoutAsTable = UserDefaults.standard.bool(forKey: kNYXPrefCollectionViewLayoutTable)
		self.layoutType = layoutAsTable ? .table : .collection
	}
}

// MARK: - UICollectionViewDataSource
extension MusicalCollectionView : UICollectionViewDataSource
{
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
	{
		if myDelegate == nil
		{
			return 0
		}

		if myDelegate.isSearching(actively: false)
		{
			return searchResults.count
		}

		return items.count
	}

	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
	{
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "fr.whine.mpdremote.cell.musicalentity", for: indexPath) as! MusicalEntityBaseCell
		cell.layer.shouldRasterize = true
		cell.layer.rasterizationScale = UIScreen.main.scale
		cell.label.textColor = #colorLiteral(red: 0.2605174184, green: 0.2605243921, blue: 0.260520637, alpha: 1)
		cell.label.backgroundColor = collectionView.backgroundColor

		// Sanity check
		let searching = myDelegate.isSearching(actively: false)
		if searching && indexPath.row >= searchResults.count
		{
			return cell
		}

		let entity = searching ? searchResults[indexPath.row] : items[indexPath.row]
		// Init cell
		cell.label.text = entity.name
		cell.accessibilityLabel = entity.name
		cell.image = nil
		switch displayType
		{
			case .albums:
				_handleCoverForCell(cell, at: indexPath, withAlbum: entity as! Album)
			case .genres:
				_configureCellForGenre(cell, indexPath: indexPath, genre: entity as! Genre)
			case .artists:
				_configureCellForArtist(cell, indexPath: indexPath, artist: entity as! Artist)
			case .playlists:
				cell.image = generateCoverForPlaylist(entity as! Playlist, size: cell.imageView.size)
		}

		return cell
	}

	private func _configureCellForGenre(_ cell: MusicalEntityBaseCell, indexPath: IndexPath, genre: Genre)
	{
		if let album = genre.albums.first
		{
			_handleCoverForCell(cell, at: indexPath, withAlbum: album)
		}
		else
		{
			if myDelegate.isSearching(actively: true)
			{
				return
			}
			MusicDataSource.shared.getAlbumsForGenre(genre, firstOnly: true) {
				if let c = self.cellForItem(at: indexPath) as? MusicalEntityBaseCell,
				let album = genre.albums.first
				{
					DispatchQueue.main.async {
						self._handleCoverForCell(c, at: indexPath, withAlbum: album)
					}
				}
			}
			return
		}
	}

	private func _configureCellForArtist(_ cell: MusicalEntityBaseCell, indexPath: IndexPath, artist: Artist)
	{
		if let album = artist.albums.first
		{
			_handleCoverForCell(cell, at: indexPath, withAlbum: album)
		}
		else
		{
			if myDelegate.isSearching(actively: true)
			{
				return
			}
			MusicDataSource.shared.getAlbumsForArtist(artist) {
				if let c = self.cellForItem(at: indexPath) as? MusicalEntityBaseCell,
				let album = artist.albums.first
				{
					DispatchQueue.main.async {
						self._handleCoverForCell(c, at: indexPath, withAlbum: album)
					}
				}
			}
		}
	}

	private func _handleCoverForCell(_ cell: MusicalEntityBaseCell, at indexPath: IndexPath, withAlbum album: Album)
	{
		// If image is in cache, bail out quickly
		if let cachedImage = ImageCache.shared[album.uniqueIdentifier]
		{
			cell.image = cachedImage
			return
		}

		// Get local URL for cover
		guard let _ = UserDefaults.standard.data(forKey: kNYXPrefWEBServer) else { return }
		guard let coverURL = album.localCoverURL else
		{
			Logger.dlog("[!] No cover file URL for \(album)") // should not happen
			return
		}

		if let cover = UIImage.loadFromFileURL(coverURL)
		{
			cell.image = cover
			ImageCache.shared[album.uniqueIdentifier] = cover
		}
		else
		{
			if let op = cell.associatedObject as! CoverOperation?
			{
				Logger.dlog("canceling \(op)")
				op.cancel()
			}

			if myDelegate.isSearching(actively: true)
			{
				return
			}

			let sizeAsData = UserDefaults.standard.data(forKey: kNYXPrefCoversSize)!
			let cropSize = NSKeyedUnarchiver.unarchiveObject(with: sizeAsData) as! NSValue
			if album.path != nil
			{
				cell.associatedObject = downloadCoverForAlbum(album, cropSize: cropSize.cgSizeValue) { (cover: UIImage, thumbnail: UIImage) in
					DispatchQueue.main.async {
						if let c = self.cellForItem(at: indexPath) as? MusicalEntityBaseCell
						{
							c.image = thumbnail
						}
					}
				}
			}
			else
			{
				MusicDataSource.shared.getPathForAlbum(album) {
					cell.associatedObject = self.downloadCoverForAlbum(album, cropSize: cropSize.cgSizeValue) { (cover: UIImage, thumbnail: UIImage) in
						DispatchQueue.main.async {
							if let c = self.cellForItem(at: indexPath) as? MusicalEntityBaseCell
							{
								c.image = thumbnail
							}
						}
					}
				}
			}
		}
	}
}

// MARK: - UICollectionViewDelegate
extension MusicalCollectionView : UICollectionViewDelegate
{
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
	{
		myDelegate.didSelectItem(indexPath: indexPath)
	}

	func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath)
	{
		// When searching things can go wrong, this prevent some crashes
		let src = myDelegate.isSearching(actively: false) ? searchResults : items
		if indexPath.row >= src.count
		{
			return
		}

		var tmpAlbum: Album? = nil
		switch (displayType)
		{
			case .albums:
				tmpAlbum = src[indexPath.row] as? Album
			case .genres:
				let genre = src[indexPath.row] as! Genre
				tmpAlbum = genre.albums.first
			case .artists:
				let artist = src[indexPath.row] as! Artist
				tmpAlbum = artist.albums.first
			case .playlists:
				tmpAlbum = nil
		}
		guard let album = tmpAlbum else { return }

		// Remove download cover operation if still in queue
		let key = album.uniqueIdentifier
		if let op = _downloadOperations[key] as! CoverOperation?
		{
			Logger.dlog("[+] Cancelling \(op)")
			_downloadOperations.removeValue(forKey: key)
			op.cancel()
		}
	}
}

// MARK: - UICollectionViewDataSourcePrefetching
extension MusicalCollectionView : UICollectionViewDataSourcePrefetching
{
	func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath])
	{
		if displayType == .albums || displayType == .playlists
		{
			return
		}

		let src = myDelegate.isSearching(actively: false) ? searchResults : items

		if displayType == .genres
		{
			for indexPath in indexPaths
			{
				if indexPath.row < src.count
				{
					let genre = src[indexPath.row] as! Genre
					if genre.albums.first == nil
					{
						MusicDataSource.shared.getAlbumsForGenre(genre, firstOnly: true) {}
					}
				}
			}
		}
		else if displayType == .artists
		{
			for indexPath in indexPaths
			{
				if indexPath.row < src.count
				{
					let artist = src[indexPath.row] as! Artist
					if artist.albums.first == nil
					{
						MusicDataSource.shared.getAlbumsForArtist(artist) {}
					}
				}
			}
		}
	}
}

// MARK: - UIScrollViewDelegate
extension MusicalCollectionView
{
	func scrollViewDidEndDecelerating(_ scrollView: UIScrollView)
	{
		self.reloadItems(at: self.indexPathsForVisibleItems)
	}
}
