# Project Plan: SwiftUI Synchronized Grid & Drag-and-Drop Demo

## **1. Project Objective**

Build a standalone SwiftUI application from scratch that demonstrates advanced grid synchronization, custom entrance animations, and seamless drag-and-drop interactions between two distinct data sets.

---

## **2. Technical Specifications**

### **A. Navigation & App Flow**

* **Root View (Home):** A simple landing interface with a navigation trigger.
* **Destination View (Workspace):** The primary demo screen containing the synchronized grids.
* **Mechanism:** Implementation of `NavigationStack` for a clean, decoupled transition.

### **B. Data & State Management**

* **Model:** A `GridItem` structure conforming to `Identifiable` and `Transferable`.
* **State:** Use an `@Observable` ViewModel to synchronize:
* **Data Arrays:** `itemsA` and `itemsB` for independent section management.
* **Dynamic Layout:** A shared `columnCount` property (e.g., 2 to 6 columns).
* **Animation State:** A `triggerShake` boolean to control the notification cue.



### **C. Grid Architecture**

* **Synchronized Scaling:** Two `LazyVGrid` components utilizing an identical `GridItem` array configuration based on the shared `columnCount`.
* **Constraint:** Items must maintain a strict 1:1 aspect ratio to ensure a consistent visual grid regardless of the number of columns.

### **D. Interactions**

* **Entrance Cue (Shake):** A custom `ViewModifier` using `.rotationEffect`. It triggers automatically on the demo screen’s `onAppear` to notify the user of interactivity.
* **Drag and Drop:**
* **Draggable:** Elements are enabled for dragging via `.draggable(item)`.
* **Drop Destination:** Each grid section acts as a `.dropDestination`.
* **Transfer Logic:** Moving an item from A to B removes it from the source array and appends it to the destination array with a `spring()` animation.



---

## **3. Execution Roadmap**

### **Phase 1: Foundation**

* Define the `NavigationStack` in the main App entry point.
* Create `HomeView` with a `NavigationLink`.
* Setup the `GridItem` model and `DemoViewModel`.

### **Phase 2: Layout & Synchronization**

* Build the `DragDropDemoView` with a `ScrollView` and two `LazyVGrid` sections.
* Implement a `Toolbar` slider to control the `columnCount` globally for both sections.

### **Phase 3: Animation & Motion**

* Develop the `ShakeEffect` modifier.
* Implement the `.onAppear` logic in the demo view to toggle the shake state briefly.

### **Phase 4: Drag & Drop Implementation**

* Apply draggable modifiers to the grid cells.
* Write the drop logic to handle array mutations (removal/insertion).
* Ensure all transitions are wrapped in `withAnimation`.

---

## **4. Component Hierarchy**

| Level | Component | Responsibility |
| --- | --- | --- |
| **0** | `NavigationStack` | App-wide navigation management. |
| **1** | `HomeView` | Entry point and demo trigger. |
| **1** | `DragDropDemoView` | Orchestrates the two grids and the layout slider. |
| **2** | `GridSection` | Renders a `LazyVGrid` and handles drop destination logic. |
| **3** | `GridCell` | Renders the 1x1 item, applies shake effect and draggable status. |

---

## **5. Success Criteria**

* Successful navigation from Home to the Demo.
* Items in Section A and B stay perfectly aligned in size when the column count changes.
* The "Shake" animation triggers correctly upon entering the demo.
* Items can be moved within a section or transferred from A to B with smooth UI updates.
