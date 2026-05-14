//
//  DropReceiver.swift
//  DragDropDemo
//
//  Created by An Nguyen on 15/5/26.
//

import Foundation

public protocol DropReceiver {
    var dropArea: CGRect? { get set }
    mutating func updateDropArea(with newDropArea: CGRect)
    func getDropArea() -> CGRect?
}

public protocol DropReceivableObservableObject: ObservableObject {
    associatedtype DropReceivable: DropReceiver
    
    func setDropArea(_ dropArea: CGRect, on dropReceiver: DropReceivable)
}


extension DropReceiver {
    public mutating func updateDropArea(with newDropArea: CGRect) {
        self.dropArea = newDropArea
    }
    
    public func getDropArea() -> CGRect? {
        dropArea ?? nil
    }
}
