var DataTypes = require("sequelize").DataTypes;
var _Pokemon = require("./pokemon");

function initModels(sequelize) {
  var Pokemon = _Pokemon(sequelize, DataTypes);


  return {
    Pokemon,
  };
}
module.exports = initModels;
module.exports.initModels = initModels;
module.exports.default = initModels;
