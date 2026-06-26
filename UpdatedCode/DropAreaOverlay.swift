//
//  DropAreaViewModifier.swift
//  DragDropDemo
//
//

import SwiftUI

fileprivate
struct FramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}


struct DropAreaOverlay<T: DropReceivableObservableObject>: ViewModifier {
    @EnvironmentObject var model: T
    let dropReceiver: T.DropReceivable
    @State var size: CGSize = .zero
    
    public func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geo in
                    Color.clear
                        .preference(
                            key: FramePreferenceKey.self,
                            value: geo.frame(in: .named(DragContainerConstant.coordinateSpaceID))
                        )
                }
                    .onPreferenceChange(FramePreferenceKey.self) { value in
                        DispatchQueue.main.async {
                            model.setDropArea(value, on: dropReceiver)
                        }
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
