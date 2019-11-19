//
//  ListView.Delegate.swift
//  Listable
//
//  Created by Kyle Van Essen on 11/19/19.
//


extension ListView
{
    final class Delegate : NSObject, UICollectionViewDelegate, ListViewLayoutDelegate
    {
        unowned var view : ListView!
        unowned var presentationState : PresentationState!
        
        // MARK: UICollectionViewDelegate
        
        func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool
        {
            return true
        }
        
        func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath)
        {
            let item = self.presentationState.item(at: indexPath)
            
            item.applyToVisibleCell()
        }
        
        func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath)
        {
            let item = self.presentationState.item(at: indexPath)
            
            item.applyToVisibleCell()
        }
        
        func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool
        {
            let item = self.presentationState.item(at: indexPath)
            
            return item.anyModel.selection.isSelectable
        }
        
        func collectionView(_ collectionView: UICollectionView, shouldDeselectItemAt indexPath: IndexPath) -> Bool
        {
            return true
        }
        
        func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
        {
            let item = self.presentationState.item(at: indexPath)
            
            item.performUserDidSelectItem(isSelected: true)
        }
        
        func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath)
        {
            let item = self.presentationState.item(at: indexPath)
            
            item.performUserDidSelectItem(isSelected: false)
        }
        
        private var displayedItems : [ObjectIdentifier:AnyPresentationItemState] = [:]
        
        func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath)
        {
            let item = self.presentationState.item(at: indexPath)
            
            item.willDisplay(cell: cell, in: collectionView, for: indexPath)
            
            self.displayedItems[ObjectIdentifier(cell)] = item
        }
        
        func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath)
        {
            guard let item = self.displayedItems.removeValue(forKey: ObjectIdentifier(cell)) else {
                return
            }
            
            item.didEndDisplay()
        }
        
        private var displayedSupplementaryItems : [ObjectIdentifier:AnyPresentationHeaderFooterState] = [:]
        
        func collectionView(_ collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, at indexPath: IndexPath)
        {
            let item : AnyPresentationHeaderFooterState = {
                switch ListViewLayout.SupplementaryKind(rawValue: elementKind)! {
                case .listHeader:
                    return self.presentationState.header!
                    
                case .listFooter:
                    return self.presentationState.footer!
                    
                case .sectionHeader:
                    let section = self.presentationState.sections[indexPath.section]
                    return section.header!
                    
                case .sectionFooter:
                    let section = self.presentationState.sections[indexPath.section]
                    return section.footer!
                }
            }()
            
            item.willDisplay(view: view, in: collectionView, for: indexPath)
            
            self.displayedSupplementaryItems[ObjectIdentifier(view)] = item
        }
        
        func collectionView(
            _ collectionView: UICollectionView,
            didEndDisplayingSupplementaryView view: UICollectionReusableView,
            forElementOfKind elementKind: String,
            at indexPath: IndexPath
            )
        {
            guard let item = self.displayedSupplementaryItems.removeValue(forKey: ObjectIdentifier(view)) else {
                return
            }
            
            item.didEndDisplay()
        }
        
        func collectionView(
            _ collectionView: UICollectionView,
            targetIndexPathForMoveFromItemAt originalIndexPath: IndexPath,
            toProposedIndexPath proposedIndexPath: IndexPath
            ) -> IndexPath
        {
            
            if originalIndexPath != proposedIndexPath {
                // TODO: Validate
                // let item = self.presentationState.item(at: originalIndexPath)
                
                if originalIndexPath.section == proposedIndexPath.section {
                    self.view.storage.moveItem(from: originalIndexPath, to: proposedIndexPath)
                    
                    return proposedIndexPath
                } else {
                    return originalIndexPath
                }
            } else {
                return proposedIndexPath
            }
        }
        
        // MARK: ListViewLayoutDelegate
        
        func listViewLayoutUpdatedItemPositions(_ collectionView : UICollectionView)
        {
            self.view.setPresentationStateItemPositions()
        }
        
        private let cellMeasurementCache = ReusableViewCache()
        
        func heightForItem(at indexPath : IndexPath, in collectionView : UICollectionView, width : CGFloat, layoutDirection : LayoutDirection) -> CGFloat
        {
            let item = self.presentationState.item(at: indexPath)
            
            return item.height(
                width: width,
                layoutDirection : layoutDirection,
                defaultHeight: self.view.layout.appearance.sizing.itemHeight,
                measurementCache: self.cellMeasurementCache
            )
        }
        
        func layoutForItem(at indexPath : IndexPath, in collectionView : UICollectionView) -> ItemLayout
        {
            let item = self.presentationState.item(at: indexPath)
            
            return item.anyModel.layout
        }
        
        func hasListHeader(in collectionView : UICollectionView) -> Bool
        {
            return self.presentationState.header != nil
        }
        
        func heightForListHeader(in collectionView : UICollectionView, width : CGFloat, layoutDirection : LayoutDirection) -> CGFloat
        {
            let header = self.presentationState.header!
            
            return header.height(
                width: width,
                layoutDirection : layoutDirection,
                defaultHeight: self.view.layout.appearance.sizing.listHeaderHeight,
                measurementCache: self.headerMeasurementCache
            )
        }
        
        func layoutForListHeader(in collectionView : UICollectionView) -> HeaderFooterLayout
        {
            let header = self.presentationState.header!
            
            return header.anyModel.layout
        }
        
        func hasListFooter(in collectionView : UICollectionView) -> Bool
        {
            return self.presentationState.footer != nil
        }
        
        func heightForListFooter(in collectionView : UICollectionView, width : CGFloat, layoutDirection : LayoutDirection) -> CGFloat
        {
            let footer = self.presentationState.footer!
            
            return footer.height(
                width: width,
                layoutDirection: layoutDirection,
                defaultHeight: self.view.layout.appearance.sizing.listFooterHeight,
                measurementCache: self.headerMeasurementCache
            )
        }
        
        func layoutForListFooter(in collectionView : UICollectionView) -> HeaderFooterLayout
        {
            let footer = self.presentationState.footer!
            
            return footer.anyModel.layout
        }
        
        func layoutFor(section sectionIndex : Int, in collectionView : UICollectionView) -> Section.Layout
        {
            let section = self.presentationState.sections[sectionIndex]
            
            return section.model.layout
        }
        
        func hasHeader(in sectionIndex : Int, in collectionView : UICollectionView) -> Bool
        {
            let section = self.presentationState.sections[sectionIndex]
            
            return section.header != nil
        }
        
        private let headerMeasurementCache = ReusableViewCache()
        
        func heightForHeader(in sectionIndex : Int, in collectionView : UICollectionView, width : CGFloat, layoutDirection : LayoutDirection) -> CGFloat
        {
            let section = self.presentationState.sections[sectionIndex]
            let header = section.header!
            
            return header.height(
                width: width,
                layoutDirection: layoutDirection,
                defaultHeight: self.view.layout.appearance.sizing.sectionHeaderHeight,
                measurementCache: self.headerMeasurementCache
            )
        }
        
        func layoutForHeader(in sectionIndex : Int, in collectionView : UICollectionView) -> HeaderFooterLayout
        {
            let section = self.presentationState.sections[sectionIndex]
            let header = section.header!
            
            return header.anyModel.layout
        }
        
        func hasFooter(in sectionIndex : Int, in collectionView : UICollectionView) -> Bool
        {
            let section = self.presentationState.sections[sectionIndex]
            
            return section.footer != nil
        }
        
        private let footerMeasurementCache = ReusableViewCache()
        
        func heightForFooter(in sectionIndex : Int, in collectionView : UICollectionView, width : CGFloat, layoutDirection : LayoutDirection) -> CGFloat
        {
            let section = self.presentationState.sections[sectionIndex]
            let footer = section.footer!
            
            return footer.height(
                width: width,
                layoutDirection: layoutDirection,
                defaultHeight: self.view.layout.appearance.sizing.sectionFooterHeight,
                measurementCache: self.headerMeasurementCache
            )
        }
        
        func layoutForFooter(in sectionIndex : Int, in collectionView : UICollectionView) -> HeaderFooterLayout
        {
            let section = self.presentationState.sections[sectionIndex]
            let footer = section.footer!
            
            return footer.anyModel.layout
        }
        
        func columnLayout(for sectionIndex : Int, in collectionView : UICollectionView) -> Section.Columns
        {
            let section = self.presentationState.sections[sectionIndex]
            
            return section.model.columns
        }
        
        // MARK: UIScrollViewDelegate
        
        func scrollViewDidEndDecelerating(_ scrollView: UIScrollView)
        {
            self.view.updatePresentationState(for: .didEndDecelerating)
        }
        
        func scrollViewDidScrollToTop(_ scrollView: UIScrollView)
        {
            self.view.updatePresentationState(for: .scrolledToTop)
        }
        
        private var lastPosition : CGFloat = 0.0
        
        func scrollViewDidScroll(_ scrollView: UIScrollView)
        {
            guard scrollView.bounds.size.height > 0 else { return }
            
            // Updating Paged Content
            
            let scrollingDown = self.lastPosition < scrollView.contentOffset.y
            
            self.lastPosition = scrollView.contentOffset.y
            
            if scrollingDown {
                self.view.updatePresentationState(for: .scrolledDown)
            }
            
            // Update Item Visibility
            
            self.view.updateVisibleItemsAndSections()
            
            // Dismiss Keyboard
            
            if self.view.behavior.dismissesKeyboardOnScroll {
                self.view.endEditing(true)
            }
        }
    }
}
