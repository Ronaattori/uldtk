const Sequelize = require('sequelize');
module.exports = function(sequelize, DataTypes) {
  return sequelize.define('Pokemon', {
    id: {
      type: DataTypes.STRING(255),
      allowNull: true,
      primaryKey: true,
      unique: true
    },
    name: {
      type: DataTypes.STRING(255),
      allowNull: true
    },
    internalname: {
      type: DataTypes.STRING(255),
      allowNull: true
    },
    type1: {
      type: DataTypes.STRING(255),
      allowNull: true
    },
    type2: {
      type: DataTypes.STRING(255),
      allowNull: true
    },
    basestats: {
      type: DataTypes.STRING(255),
      allowNull: true
    },
    genderrate: {
      type: DataTypes.STRING(255),
      allowNull: true
    },
    growthrate: {
      type: DataTypes.STRING(255),
      allowNull: true
    },
    baseexp: {
      type: DataTypes.STRING(255),
      allowNull: true
    },
    effortpoints: {
      type: DataTypes.STRING(255),
      allowNull: true
    },
    rareness: {
      type: DataTypes.STRING(255),
      allowNull: true
    },
    happiness: {
      type: DataTypes.STRING(255),
      allowNull: true
    },
    abilities: {
      type: DataTypes.STRING(255),
      allowNull: true
    },
    hiddenability: {
      type: DataTypes.STRING(255),
      allowNull: true
    },
    moves: {
      type: DataTypes.STRING(255),
      allowNull: true
    },
    tutormoves: {
      type: DataTypes.STRING(255),
      allowNull: true
    },
    eggmoves: {
      type: DataTypes.STRING(255),
      allowNull: true
    },
    compatibility: {
      type: DataTypes.STRING(255),
      allowNull: true
    },
    stepstohatch: {
      type: DataTypes.STRING(255),
      allowNull: true
    },
    height: {
      type: DataTypes.STRING(255),
      allowNull: true
    },
    weight: {
      type: DataTypes.STRING(255),
      allowNull: true
    },
    color: {
      type: DataTypes.STRING(255),
      allowNull: true
    },
    shape: {
      type: DataTypes.STRING(255),
      allowNull: true
    },
    habitat: {
      type: DataTypes.STRING(255),
      allowNull: true
    },
    kind: {
      type: DataTypes.STRING(255),
      allowNull: true
    },
    pokedex: {
      type: DataTypes.STRING(255),
      allowNull: true
    },
    generation: {
      type: DataTypes.STRING(255),
      allowNull: true
    },
    battlerplayerx: {
      type: DataTypes.STRING(255),
      allowNull: true
    },
    battlerplayery: {
      type: DataTypes.STRING(255),
      allowNull: true
    },
    battlerenemyx: {
      type: DataTypes.STRING(255),
      allowNull: true
    },
    battlerenemyy: {
      type: DataTypes.STRING(255),
      allowNull: true
    },
    battlershadowx: {
      type: DataTypes.STRING(255),
      allowNull: true
    },
    battlershadowsize: {
      type: DataTypes.STRING(255),
      allowNull: true
    },
    evolutions: {
      type: DataTypes.STRING(255),
      allowNull: true
    },
    wilditemuncommon: {
      type: DataTypes.STRING(255),
      allowNull: true
    },
    wilditemcommon: {
      type: DataTypes.STRING(255),
      allowNull: true
    },
    wilditemrare: {
      type: DataTypes.STRING(255),
      allowNull: true
    },
    formname: {
      type: DataTypes.STRING(255),
      allowNull: true
    },
    incense: {
      type: DataTypes.STRING(255),
      allowNull: true
    }
  }, {
    sequelize,
    tableName: 'pokemon',
    timestamps: true,
    indexes: [
      {
        name: "sqlite_autoindex_pokemon_1",
        unique: true,
        fields: [
          { name: "id" },
        ]
      },
    ]
  });
};
