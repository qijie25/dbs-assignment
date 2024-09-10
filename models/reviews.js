const { query } = require("../database");
const {
  EMPTY_RESULT_ERROR,
  SQL_ERROR_CODE,
  UNIQUE_VIOLATION_ERROR,
} = require("../errors");

module.exports.create = function create(memberId, productId, orderId, rating, reviewText) {
  const sql = `CALL create_review($1, $2, $3, $4, $5)`;
  return query(sql, [memberId, productId, orderId, rating, reviewText])
    .then(function (result) {
      console.log("Module created successfully");
    })
    .catch(function (error) {
      if (error.code === SQL_ERROR_CODE.UNIQUE_VIOLATION) {
        throw new UNIQUE_VIOLATION_ERROR(`Review ${productId} already exists!
    Cannot create duplicate.`);
      }
      throw error;
    });
};

module.exports.retrieveAll = function retrieveAll(memberId) {
  const sql = `SELECT * FROM get_all_reviews($1)`;
  return query(sql, [memberId]).then(function (result) {
    console.log('Query Result:', result.rows);
    return result.rows;
  });
}

module.exports.retrieveById = function retrieveById(memberId, id) {
  const sql = `SELECT * FROM get_review($1, $2)`;
  return query(sql, [parseInt(id), parseInt(memberId)]).then(function (result) {
      const rows = result.rows;

      if (rows.length === 0) {
          throw new Error(`Review ${id} not found!`);
      }

      return rows[0];
  });
};

module.exports.updateById = function updateById(id, rating, reviewText) {
  const sql = `CALL update_review($1, $2, $3)`;
  return query(sql, [id, rating, reviewText]).then(function (result) {
      const rows = result.rowCount;

      if (rows === 0) {
          throw new EMPTY_RESULT_ERROR(`Review ${id} not found!`);
      }
  })
};

module.exports.deleteById = function deleteById(id) {
  const sql = `CALL delete_review($1)`;
  return query(sql, [id]).then(function (result) {
    const rows = result.rowCount;

    if (rows === 0) {
      throw new EMPTY_RESULT_ERROR(`Review ${id} not found`);
    }
  })
}
