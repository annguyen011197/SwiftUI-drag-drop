//
//  DropAreaViewModifier.swift
//  DragDropDemo
//
//  Created by An Nguyen on 15/5/26.
//

import SwiftUI

struct DropAreaOverlay<T: DropReceivableObservableObject>: ViewModifier {
    @EnvironmentObject var model: T
    let dropReceiver: T.DropReceivable
    
    public func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    Color.clear
                        .onAppear {
                            model.setDropArea(geo.frame(in: .named(DragContainerConstant.coordinateSpaceID)), on: dropReceiver)
                        }
                        #if os(iOS)
                        .onRotate { _ in
                            model.setDropArea(geo.frame(in: .named(DragContainerConstant.coordinateSpaceID)), on: dropReceiver)
                        }
                        #endif
                }
            )
    }
}

extension View {
    public func dropReceiver<T: DropReceivableObservableObject>(for dropReceiver: T.DropReceivable, model: T) -> some View {
        modifier(DropAreaOverlay<T>(dropReceiver: dropReceiver))
            .environmentObject(model)
    }
}

#if os(iOS)
struct DeviceRotationViewModifier: ViewModifier {
    let action: (UIDeviceOrientation) -> Void

    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                Task(priority: .low) {
                    action(UIDevice.current.orientation)
                }
            }
    }
}

extension View {
    func onRotate(perform action: @escaping (UIDeviceOrientation) -> Void) -> some View {
        self.modifier(DeviceRotationViewModifier(action: action))
    }
}
#endif
