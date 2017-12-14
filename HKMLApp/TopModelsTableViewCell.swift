//
//  TopModelsTableViewCell.swift
//  test_master_detail
//
//  Created by Richard So on 24/11/2017.
//  Copyright © 2017 Netrogen Creative. All rights reserved.
//

import UIKit

class TopModelsTableViewCell: UITableViewCell {
    
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var section: UILabel!
    @IBOutlet weak var date: UILabel!
    @IBOutlet weak var imageThumb: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
