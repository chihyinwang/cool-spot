import unittest
from build_catalogue import evaluate, availability

class MappingTests(unittest.TestCase):
    def candidate(self, **changes):
        return {'placeID':'apple-id','name':'Example Library','address':'12 Example Road','postalCode':'SE1 1AA',
                'distanceMetres':40, **changes}
    def source(self, **changes):
        return {'cs_name':'Example Library','cs_address_one':'12 Example Road','cs_postcode':'SE1 1AA',**changes}
    def accepted(self, source, candidate):
        return evaluate(source,[candidate])[0]['evidence']['meetsAutomaticRule']
    def test_exact_name_address_and_nearby_candidate_qualifies(self):
        self.assertTrue(self.accepted(self.source(),self.candidate()))
    def test_same_branch_name_far_away_never_qualifies(self):
        self.assertFalse(self.accepted(self.source(),self.candidate(distanceMetres=800)))
    def test_proximity_alone_never_qualifies(self):
        self.assertFalse(self.accepted(self.source(),self.candidate(name='Example Cafe')))
    def test_conflicting_street_numbers_require_review_even_when_postcode_agrees(self):
        self.assertFalse(self.accepted(self.source(),self.candidate(address='18 Example Road')))
    def test_generic_street_word_is_not_address_agreement(self):
        self.assertFalse(self.accepted(self.source(cs_postcode=None),self.candidate(address='Road',postalCode='')))
    def test_conflicting_postcodes_require_review_even_when_street_agrees(self):
        self.assertFalse(self.accepted(self.source(),self.candidate(postalCode='SE1 1AB')))
    def test_missing_apple_identity_never_qualifies(self):
        self.assertFalse(self.accepted(self.source(),self.candidate(placeID='')))
    def test_unknown_source_answer_is_not_false(self):
        for value in [None,'','future_answer']: self.assertEqual(availability(value),'unknown')
        self.assertEqual(availability(' Yes '),'yes')

if __name__=='__main__': unittest.main()
