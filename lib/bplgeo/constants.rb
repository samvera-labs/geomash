module Bplgeo
  class Constants
    COUNTRY_TGN_LOOKUP = {}
    COUNTRY_TGN_LOOKUP['United States'] = {:tgn_id=>7012149, :tgn_country_name=>'United States'}
    COUNTRY_TGN_LOOKUP['Canada'] = {:tgn_id=>7005685, :tgn_country_name=>'Canada'}
    COUNTRY_TGN_LOOKUP['France'] = {:tgn_id=>1000070, :tgn_country_name=>'France'}
    COUNTRY_TGN_LOOKUP['Vietnam'] = {:tgn_id=>1000145, :tgn_country_name=>'Viet Nam'}
    COUNTRY_TGN_LOOKUP['South Africa'] = {:tgn_id=>1000193, :tgn_country_name=>'South Africa'}
    COUNTRY_TGN_LOOKUP['Philippines'] = {:tgn_id=>1000135, :tgn_country_name=>'Pilipinas'}
    COUNTRY_TGN_LOOKUP['China'] = {:tgn_id=>1000111, :tgn_country_name=>'Zhongguo'}
    COUNTRY_TGN_LOOKUP['Japan'] = {:tgn_id=>1000120, :tgn_country_name=>'Nihon'}

    STATE_ABBR = {
        'AL' => 'Alabama',
        'AK' => 'Alaska',
        'AS' => 'America Samoa',
        'AZ' => 'Arizona',
        'AR' => 'Arkansas',
        'CA' => 'California',
        'CO' => 'Colorado',
        'CT' => 'Connecticut',
        'DE' => 'Delaware',
        'DC' => 'District of Columbia',
        'FM' => 'Micronesia1',
        'FL' => 'Florida',
        'GA' => 'Georgia',
        'GU' => 'Guam',
        'HI' => 'Hawaii',
        'ID' => 'Idaho',
        'IL' => 'Illinois',
        'IN' => 'Indiana',
        'IA' => 'Iowa',
        'KS' => 'Kansas',
        'KY' => 'Kentucky',
        'LA' => 'Louisiana',
        'ME' => 'Maine',
        'MH' => 'Islands1',
        'MD' => 'Maryland',
        'MA' => 'Massachusetts',
        'MI' => 'Michigan',
        'MN' => 'Minnesota',
        'MS' => 'Mississippi',
        'MO' => 'Missouri',
        'MT' => 'Montana',
        'NE' => 'Nebraska',
        'NV' => 'Nevada',
        'NH' => 'New Hampshire',
        'NJ' => 'New Jersey',
        'NM' => 'New Mexico',
        'NY' => 'New York',
        'NC' => 'North Carolina',
        'ND' => 'North Dakota',
        'OH' => 'Ohio',
        'OK' => 'Oklahoma',
        'OR' => 'Oregon',
        'PW' => 'Palau',
        'PA' => 'Pennsylvania',
        'PR' => 'Puerto Rico',
        'RI' => 'Rhode Island',
        'SC' => 'South Carolina',
        'SD' => 'South Dakota',
        'TN' => 'Tennessee',
        'TX' => 'Texas',
        'UT' => 'Utah',
        'VT' => 'Vermont',
        'VI' => 'Virgin Island',
        'VA' => 'Virginia',
        'WA' => 'Washington',
        'WV' => 'West Virginia',
        'WI' => 'Wisconsin',
        'WY' => 'Wyoming'
    }

    #Terms that drive geographic parsers mad...
    JUNK_TERMS = [
        'Cranberries',
        'History',
        'Maps',
        'State Police',
        'Pictorial works.',
        /[nN]ation/,
        'Asia',
        '(Republic)'
    ]
  end
end