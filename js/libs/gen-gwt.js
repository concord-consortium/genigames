GenGWT = {

    // 'callback' should be a function that takes a dragon (GOrganism)
    generateDragon: function(callback) {
        generateDragonWithCallback(this.wrapCallback(callback), this.failure);
    },

    generateDragonWithSex: function(sex, callback) {
        generateDragonWithSex(sex, this.wrapCallback(callback), this.failure);
    },
    
    generateAliveDragonWithSex: function(sex, callback) {
        var wrappedCallback = function (gOrg){
          if (GenGWT.isAlive(gOrg)){
            callback(gOrg);
          } else {
            GenGWT.generateAliveDragonWithSex(sex, callback);
          }
        }
        generateDragonWithSex(sex, wrappedCallback, this.failure);
    },

    generateDragonWithAlleleString: function(alleles, callback) {
      if (!alleles) {
        if (!!console) { console.error("Need to define alleles!"); } // console.trace(); }
      } else {
        generateDragonWithAlleleString(alleles, this.wrapCallback(callback), this.failure);
      }
    },

    generateDragonWithAlleleStringAndSex: function(alleles, sex, callback) {
      if (!alleles) {
        if (!!console) { console.error("Need to define alleles!"); } // console.trace(); }
      } else {
        generateDragonWithAlleleStringAndSex(alleles, sex, this.wrapCallback(callback), this.failure);
      }
    },

    breedDragon: function(mother, father, callback) {
        breedDragon(mother, father, this.wrapCallback(callback), this.failure);
    },
    
    breedDragons: function(number, mother, father, crossover, callback) {
        breedDragonsWithCrossover(number, mother, father, crossover, this.wrapCallback(callback), this.failure);
    },

    isAlive: function(dragon) {
        return this.hasCharacteristic(dragon, "Alive");
    },

    setAlleles: function(string) {
        var allelesArray = string.split("|");
        if (allelesArray.length == 1) {
            this.currentAlleleStringF = allelesArray[0];
            this.currentAlleleStringM = allelesArray[0];
        } else if (allelesArray.length == 2) {
            this.currentAlleleStringF = allelesArray[0];
            this.currentAlleleStringM = allelesArray[1];
        }
    },

    currentAlleleStringM: "",

    currentAlleleStringF: "",

    hasCharacteristic: function(dragon, characteristic) {
        function contains(arrayList, obj) {
            var array = arrayList.array;
            var i = array.length;
            while (i--) {
                if (array[i] == obj) {
                    return true;
                }
            }
            return false;
        }

        return contains(dragon.characteristics, characteristic);
    },

    createDragon: function(jsonDragon) {
        return createGOrganismFromJSONString(JSON.stringify(jsonDragon));
    },

    getCharacteristics: function(dragon, callback) {
        getDragonCharacteristics(dragon, callback, this.failure);
    },
    
    wrapCallback: function(callback) {
      function wrappedCallback(gOrg){
        if (GenGWT.orgIsValid(gOrg)){
          callback(gOrg);
        } else {
          console.log("WARN: Organism generated was not valid");
          console.log(gOrg);
          SC.AlertPane.error("", "The application created an invalid Drake. Please reload the page and try again.");
        }
      }
      return wrappedCallback;
    },
    
    orgIsValid: function(gOrg) {
      if (!!gOrg.size){
        var allAreValid = true;
        for (var i = 0; i < gOrg.size; i++) {
          if (!GenGWT.orgIsValid(gOrg.array[i])) {
            allAreValid = false;
          }
        }
        return allAreValid;
      }
      return (!!gOrg.alleles && (!!gOrg.sex || gOrg.sex == 0) && !!gOrg.imageURL);
    },

    failure: function(errorMsg) {
        SC.Logger.error("failure on GWT callback");
        SC.Logger.error(errorMsg);
        SC.Logger.trace();
    },

    isLoaded: function() {
      SC.Logger.log("Checking if loaded. Is:  " + (typeof(generateDragonWithCallback) != "undefined"));
	    return (typeof(generateDragonWithCallback) != "undefined");
		}
};
