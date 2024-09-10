const { EMPTY_RESULT_ERROR, UNIQUE_VIOLATION_ERROR, DUPLICATE_TABLE_ERROR } = require('../errors');
const saleOrdersModel = require('../models/saleOrders');
const membersModel = require('../models/members');

module.exports.retrieveAll = function (req, res) {
    const memberId = res.locals.member_id;
    const filters = {
        ...req.query,
        memberId,
    };

    membersModel
        .isAdmin(memberId)
        .then(function (isAdmin) {
            if (isAdmin) {
                filters.memberId = null; 
            }

            return saleOrdersModel.retrieveAll(filters);
        })
        .then(function (saleOrderItems) {
            return res.json({ saleOrderItems: saleOrderItems });
        })
        .catch(function (error) {
            console.error(error);
            if (error instanceof EMPTY_RESULT_ERROR) {
                return res.status(404).json({ error: error.message });
            }
            return res.status(500).json({ error: error.message });
        });
};
