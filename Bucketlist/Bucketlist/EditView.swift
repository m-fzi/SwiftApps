//
//  EditView.swift
//  Bucketlist
//
//  Created by Paul Hudson on 09/12/2021.
//

import SwiftUI

struct EditView: View {
    enum LoadingState {
        case loading, loaded, failed
    }

    @Environment(\.dismiss) var dismiss
    var location: Location
    var onSave: (Location) -> Void

    @State private var name: String
    @State private var description: String

    @State private var loadingState = LoadingState.loading
    @State private var pages = [Page]()

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Place name", text: $name)
                    TextField("Description", text: $description)
                }

                Section("Nearby…") {
                    switch loadingState {
                    case .loading:
                        Text("Loading…")
                    case .loaded:
                        ForEach(pages, id: \.pageid) { page in
                            Text(page.title)
                                .font(.headline)
                            + Text(": ")
                            + Text(page.description)
                                .italic()
                        }
                    case .failed:
                        Text("Please try again later.")
                    }
                }
            }
            .navigationTitle("Place details")
            .toolbar {
                Button("Save") {
                    var newLocation = location
                    newLocation.id = UUID() // When we want to update locations list, if we don't give this newLocation a new UUID() program will see the two items are same(because on Location struct, we told to do equation(==) just by looking UUIDs) and will not update location instance. (program will
                    newLocation.name = name
                    newLocation.description = description

                    onSave(newLocation)
                    dismiss()
                }
            }
            .task {
                await fetchNearbyPlaces()
            }
        }
    }

    init(location: Location, onSave: @escaping (Location) -> Void) {
        self.location = location
        self.onSave = onSave

        _name = State(initialValue: location.name)  //IMPORTANT: Here, we are assigning a value to '@State var name'. Not 'var name'. 'var name' is a string. But '@State var name' is a State object(name wrapped by State). So we are editing the value of wrapped package here. To refer that wrapped package we are using _varName.
        _description = State(initialValue: location.description)
    }

    func fetchNearbyPlaces() async {
        let urlString = "https://en.wikipedia.org/w/api.php?ggscoord=53%7C0.06&action=query&prop=coordinates%7Cpageimages%7Cpageterms&colimit=50&piprop=thumbnail&pithumbsize=500&pilimit=50&wbptterms=description&generator=geosearch&ggsradius=10000&ggslimit=50&format=json"

        guard let url = URL(string: urlString) else {
            print("Bad URL: \(urlString)")
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let items = try JSONDecoder().decode(Result.self, from: data)
            pages = items.query.pages.values.sorted()
            loadingState = .loaded
        } catch {
            loadingState = .failed
        }
    }
}

struct EditView_Previews: PreviewProvider {
    static var previews: some View {
        EditView(location: Location.example) { _ in }
    }
}
