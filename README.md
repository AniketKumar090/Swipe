# Swipe iOS App

A SwiftUI-based iOS application for managing products with offline capabilities. This app allows users to view, search, and add products while maintaining favorite products locally.

## Features

- Product listing with search functionality
- Add new products with image support
- Offline product creation
- Favorite products management
- Real-time product synchronization
- Modern SwiftUI interface with MVVM architecture

## Requirements

- Xcode 15.0+
- iOS 16.0+
- Swift 5.9+
- macOS Ventura 13.0+ (for development)

## Installation

1. Clone the repository:
```bash
git clone https://github.com/AniketKumar090/Swipe.git
cd Swipe
```

2. Open the project in Xcode:
```bash
open Swipe.xcodeproj
```

3. Install dependencies (if using CocoaPods or SPM):
   - The project uses Swift Package Manager for dependencies
   - Dependencies will be resolved automatically when opening the project in Xcode


## Architecture

The app follows the MVVM (Model-View-ViewModel) architecture pattern:

- **Models**: Define the data structure for products and API responses
- **Views**: SwiftUI views for displaying the UI
- **ViewModels**: Handle business logic and data transformation
- **Services**: Manage API communication and local storage

## Key Components

### Networking
- `APIClient`: Handles all API communications
- `ProductService`: Manages product-related API calls
- Offline support with request queuing

### Storage
- `CoreDataManager`: Handles local data persistence
- `UserDefaultsManager`: Manages user preferences and favorites

### UI Components
- Custom reusable views
- Loading indicators
- Error handling views
- Image caching system

## Running the App

1. Select your target device/simulator in Xcode
2. Press ⌘R or click the "Run" button
3. The app will build and launch on your selected device

## Offline Functionality

The app implements offline support through:
1. Local storage of products using CoreData
2. Request queuing system for offline changes
3. Automatic synchronization when online
4. Conflict resolution strategies

## API Integration

The app integrates with the following endpoints:
- GET `https://app.getswipe.in/api/public/get` - Fetch products
- POST `https://app.getswipe.in/api/public/add` - Add new product

## Troubleshooting

Common issues and solutions:

1. **Build Errors**
   - Clean build folder (Shift + ⌘ + K)
   - Clean derived data
   - Ensure Xcode version compatibility

2. **Runtime Issues**
   - Check internet connectivity
   - Verify API endpoint accessibility
   - Clear app data and reinstall

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE.md file for details

## Contact

For any queries or support, please contact:
- Aniket Kumar
- Email: kumaraniket009@gmail.com
- GitHub: @AniketKumar090

## Version History

- 1.0.0
  - Initial release
  - Basic product management functionality
  - Offline support
