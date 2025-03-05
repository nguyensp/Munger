//
//  CollectiveMemoryModels.swift
//  Munger
//
//  Created by Paul Nguyen on 3/4/25.
//

import Foundation

struct EmbeddingResponse: Codable {
    struct EmbeddingData: Codable {
        let embedding: [Float]
    }
    let data: [EmbeddingData]
}

