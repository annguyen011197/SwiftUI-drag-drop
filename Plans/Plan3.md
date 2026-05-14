# Custom Drag & Drop

1. Change GridView logic:
  - Instaed of using VStack + HStack to render GridView
  - Change to use ZStack, then calculate and control offset of each item 
  - Code example: ./ZStackGrid.swift

2. Use DragContainer, DragManager, and preview thumbnail
  - Code idea: ./DragHelper.swift
