import Foundation

// A public response writes explicit nulls for nullable keys. Legacy aliases are read-only.
extension CoolSpotsResponse.Item {
    enum CodingKeys: String, CodingKey { case id, name, location, address, placeType, setting, coolingFeatures, additionalInformation, coolingDetails, access, hours, sourceRecord, appleMatch, sourceReferences, mapReferences, photos, provenance }
    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(id, forKey: .id)
        try values.encode(name, forKey: .name)
        try values.encode(location, forKey: .location)
        try values.encode(address, forKey: .address)
        try values.encode(placeType, forKey: .placeType)
        try values.encode(setting, forKey: .setting)
        try values.encode(coolingFeatures, forKey: .coolingFeatures)
        try values.encode(additionalInformation, forKey: .additionalInformation)
        try values.encode(coolingDetails, forKey: .coolingDetails)
        try values.encode(access, forKey: .access)
        try values.encode(hours, forKey: .hours)
        try values.encode(sourceReferences ?? [], forKey: .sourceReferences)
        try values.encode(mapReferences ?? [], forKey: .mapReferences)
        try values.encode(photos ?? [], forKey: .photos)
        try values.encode(provenance ?? [], forKey: .provenance)
    }
}

extension CoolSpotsResponse.Item.Address {
    enum CodingKeys: String, CodingKey { case formatted, line1, line2, locality, borough, postalCode, countryCode }
    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(formatted, forKey: .formatted)
        try values.encode(line1, forKey: .line1)
        try values.encode(line2, forKey: .line2)
        try values.encode(locality, forKey: .locality)
        try values.encode(borough, forKey: .borough)
        try values.encode(postalCode, forKey: .postalCode)
        try values.encode(countryCode, forKey: .countryCode)
    }
}

extension CoolSpotsResponse.Item.Location {
    enum CodingKeys: String, CodingKey { case latitude, longitude, scope }
    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(latitude, forKey: .latitude)
        try values.encode(longitude, forKey: .longitude)
        try values.encode(scope ?? .unknown, forKey: .scope)
    }
}

extension CoolSpotsResponse.Item.Access {
    enum CodingKeys: String, CodingKey { case cost, eligibility, eligibilityDetails, seating, drinkingWater, toilets, wheelchairAccess, staffedWhenOpen, tables, instructions, postedStayLimitMinutes, areaDescription, postedStayLimit }
    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(cost, forKey: .cost)
        try values.encode(eligibility, forKey: .eligibility)
        try values.encode(eligibilityDetails, forKey: .eligibilityDetails)
        try values.encode(seating, forKey: .seating)
        try values.encode(drinkingWater, forKey: .drinkingWater)
        try values.encode(toilets, forKey: .toilets)
        try values.encode(wheelchairAccess, forKey: .wheelchairAccess)
        try values.encode(staffedWhenOpen ?? .unknown, forKey: .staffedWhenOpen)
        try values.encode(tables ?? .unknown, forKey: .tables)
        try values.encode(areaDescription ?? instructions, forKey: .areaDescription)
        try values.encode(resolvedStayLimit, forKey: .postedStayLimit)
    }
}

extension CoolSpotsResponse.Item.Provenance {
    enum CodingKeys: String, CodingKey { case sourceID, recordID, method, fields, recordedAt }
    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(sourceID, forKey: .sourceID)
        try values.encode(recordID, forKey: .recordID)
        try values.encode(method, forKey: .method)
        try values.encode(fields, forKey: .fields)
        try values.encode(recordedAt, forKey: .recordedAt)
    }
}

extension PlacePhotoAsset {
    enum CodingKeys: String, CodingKey { case id, thumbnailURL, imageURL, width, height, caption, capturedAt, publishedAt, attribution, source, contributionID }
    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(id, forKey: .id)
        try values.encode(thumbnailURL, forKey: .thumbnailURL)
        try values.encode(imageURL, forKey: .imageURL)
        try values.encode(width, forKey: .width)
        try values.encode(height, forKey: .height)
        try values.encode(caption, forKey: .caption)
        try values.encode(capturedAt, forKey: .capturedAt)
        try values.encode(publishedAt, forKey: .publishedAt)
        try values.encode(attribution, forKey: .attribution)
        try values.encode(source, forKey: .source)
        try values.encode(contributionID, forKey: .contributionID)
    }
}

extension CoolSpotStayLimit {
    enum CodingKeys: String, CodingKey { case status, minutes }
    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(status, forKey: .status)
        try values.encode(minutes, forKey: .minutes)
    }
}

extension CoolSpotsResponse.Item.MapReference {
    enum CodingKeys: String, CodingKey { case provider, placeID, relationship, verification, checkedAt }
    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(provider, forKey: .provider)
        try values.encode(placeID, forKey: .placeID)
        try values.encode(relationship, forKey: .relationship)
        try values.encode(verification, forKey: .verification)
        try values.encode(checkedAt, forKey: .checkedAt)
    }
}
