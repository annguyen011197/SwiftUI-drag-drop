//
//  DropReceiver.swift
//  DragDropDemo
//
//

import Foundation



public protocol DropReceiver {
    var dropArea: CGRect? { get set }
    var dropAreaPadding: (top: CGFloat, left: CGFloat, bottom: CGFloat, right: CGFloat) { get }
    var effectiveDropArea: CGRect? { get }
    mutating func updateDropArea(with newDropArea: CGRect)
    func getDropArea() -> CGRect?
}

public protocol DropReceivableObservableObject: ObservableObject {
    associatedtype DropReceivable: DropReceiver
    
    func setDropArea(_ dropArea: CGRect, on dropReceiver: DropReceivable)
}


extension DropReceiver {
    public var effectiveDropArea: CGRect? {
        guard let dropArea else { return nil }
        return CGRect(
            x: dropArea.origin.x - dropAreaPadding.left,
            y: dropArea.origin.y - dropAreaPadding.top,
            width: dropArea.width + dropAreaPadding.left + dropAreaPadding.right,
            height: dropArea.height + dropAreaPadding.top + dropAreaPadding.bottom
        )
    }
    public mutating func updateDropArea(with newDropArea: CGRect) {
        self.dropArea = newDropArea
    }
    
    public func getDropArea() -> CGRect? {
        dropArea ?? nil
    }
}
