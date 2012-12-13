(function() {

  describe("A student", function() {
    var flag, runAndWait, vars;
    vars = {};
    flag = false;
    runAndWait = function(msg, time, action, result) {
      runs(function() {
        flag = false;
        action();
        return setTimeout(function() {
          return flag = true;
        }, time);
      });
      waitsFor(function() {
        return flag;
      }, time + 100);
      if (result != null) {
        return runs(function() {
          return result();
        });
      }
    };
    beforeEach(function() {
      return $('#container').show();
    });
    afterEach(function() {
      return $('#container').hide();
    });
    it("should start with zero reputation", function() {
      return runAndWait("Pause", 5000, function() {
        return console.log('waiting for load');
      }, function() {
        return expect(GG.userController.get('user.reputation')).toBe(0);
      });
    });
    it("should be able to click on the first town", function() {
      expect(GG.townsController.get('currentTown')).toBe(null);
      expect($('#world').length).toBe(1);
      expect($('.townIcon1').length).toBe(1);
      return runAndWait("Castle should be clicked", 3000, function() {
        return Ember.run(function() {
          return $('.townIcon1').click();
        });
      }, function() {
        expect($('#world').length).toBe(0);
        expect($('.townIcon1').length).toBe(0);
        expect($('#town').length).toBe(1);
        return expect(GG.townsController.get('currentTown')).toBe(GG.townsController.get('content')[0]);
      });
    });
    it("should see the npc and bubble", function() {
      expect($('.npc').length).toBeGreaterThan(0);
      return expect($('.npc .bubble').length).toBeGreaterThan(0);
    });
    it("should be able to click the bubble", function() {
      return runAndWait("Question bubble should be clicked", 200, function() {
        return Ember.run(function() {
          return $('.npc a img:not(.hidden)').click();
        });
      }, function() {
        expect($('.npc a img:not(.hidden)').length).toBe(0);
        return expect($('.npc .speech-bubble:not(.hidden)').length).toBe(1);
      });
    });
    it("should be able to accept the task, and the breeding view slides in", function() {
      expect($('.npc .speech-bubble:not(.hidden) button:contains("Ok")').length).toBe(1);
      expect(parseInt($('#breeding-apparatus').css('left'))).toBeGreaterThan(1000);
      return runAndWait("Task should be accepted, breeding machine should load", 400, function() {
        return Ember.run(function() {
          return $('.npc .speech-bubble:not(.hidden) button:contains("Ok")')[0].click();
        });
      }, function() {
        expect($('.npc .speech-bubble:not(.hidden)').length).toBe(0);
        expect($('.heart-bubble:not(.hidden)').length).toBe(0);
        expect($('.npc a img:not(.hidden)').length).toBe(0);
        expect(parseInt($('#breeding-apparatus').css('left'))).toBeLessThan(1000);
        expect(GG.tasksController.get('currentTask')).toBe(GG.tasksController.get('content')[0]);
        expect(GG.parentController.get('selectedMother')).toBe(null);
        expect(GG.parentController.get('selectedFather')).toBe(null);
        expect(GG.parentController.get('content').length).toBe(4);
        expect($('#father-chromosome .chromosome-panel.hidden').length).toBe(1);
        expect($('#mother-chromosome .chromosome-panel.hidden').length).toBe(1);
        expect(GG.breedingController.get('child')).toBe(null);
        return expect(GG.cyclesController.get('cycles')).toBe(10);
      });
    });
    it("should not see chromosome panels", function() {
      expect($('#father-chromosome .chromosome-panel.hidden').length).toBe(1);
      return expect($('#mother-chromosome .chromosome-panel.hidden').length).toBe(1);
    });
    it("should see a disabled breed button", function() {
      return expect($('#breed-button:not(.enabled)').length).toBe(1);
    });
    it("should be able to select parents", function() {
      runAndWait("Mother should be selectable", 500, function() {
        return Ember.run(function() {
          var parents;
          parents = $('#parent-mothers-pool-container .parent a');
          expect(parents.length).toBe(2);
          return parents[0].click();
        });
      }, function() {
        expect(GG.parentController.get('selectedMother')).toNotBe(null);
        return expect($('#breed-button.enabled').length).toBe(0);
      });
      return runAndWait("Father should be selectable", 500, function() {
        return Ember.run(function() {
          var parents;
          parents = $('#parent-fathers-pool-container .parent a');
          expect(parents.length).toBe(2);
          return parents[0].click();
        });
      }, function() {
        expect(GG.parentController.get('selectedFather')).toNotBe(null);
        return expect($('#breed-button.enabled').length).toBe(1);
      });
    });
    it("should see chromosome panels", function() {
      expect($('#father-chromosome .chromosome-panel:not(.hidden)').length).toBe(1);
      return expect($('#mother-chromosome .chromosome-panel:not(.hidden)').length).toBe(1);
    });
    it("should see an enabled breed button", function() {
      return expect($('#breed-button.enabled').length).toBe(1);
    });
    it("should be able to breed the two parents and get an offspring", function() {
      GG.MeiosisAnimation.set('timeScale', 0.2);
      return runAndWait("Breeding should be successful", 9000, function() {
        return Ember.run(function() {
          return $('#breed-button.enabled')[0].click();
        });
      }, function() {
        expect(GG.breedingController.get('child')).toNotBe(null);
        return expect(GG.offspringController.get('content')).toNotBe(null);
      });
    });
    it("should see that cycles has decreased to 9", function() {
      return expect(GG.cyclesController.get('cycles')).toBe(9);
    });
    it("should be able to breed again and decrease cycles to 8", function() {
      return runAndWait("Breed", 9000, function() {
        return Ember.run(function() {
          return $('#breed-button.enabled')[0].click();
        });
      }, function() {
        return expect(GG.cyclesController.get('cycles')).toBe(8);
      });
    });
    it("should be able to move offspring to parent pool", function() {
      vars.offspringSex = null;
      return runAndWait("Offspring can be moved to the parent pool", 200, function() {
        vars.offspringSex = GG.breedingController.getPath('child.sex');
        return $('.offspring-buttons-save').click();
      }, function() {
        var newParents, pool;
        expect(GG.parentController.get('content').length).toBe(5);
        expect(GG.offspringController.get('content')).toBe(null);
        pool = vars.offspringSex === GG.MALE ? "#parent-fathers-pool-container" : "#parent-mothers-pool-container";
        newParents = $(pool + ' .parent a:not(.removeButton)');
        return expect(newParents.length).toBe(3);
      });
    });
    it("should decrease reputation to -1", function() {
      return expect(GG.userController.get('user.reputation')).toBe(-1);
    });
    it("should be able to select offspring and breed with it", function() {
      return runAndWait("Go back to select parents", 800, function() {
        return $('.select-parents').click();
      }, function() {
        return runAndWait("Offspring can be used to breed", 11000, function() {
          var pool;
          console.log(vars.offspringSex);
          pool = vars.offspringSex === GG.MALE ? "#parent-fathers-pool-container" : "#parent-mothers-pool-container";
          console.log(pool);
          $(pool + " .parent a")[2].click();
          return $('#breed-button').click();
        }, function() {
          expect(GG.breedingController.get('child')).toNotBe(null);
          expect(GG.offspringController.get('content')).toNotBe(null);
          return expect(GG.cyclesController.get('cycles')).toBe(7);
        });
      });
    });
    it("should get a reject message if they submit an incorrect drake", function() {
      var impossibleTask;
      expect($('.speech-bubble-no-npc:not(.hidden)').length).toBe(0);
      vars.offspringHasWings = GG.breedingController.get('child').get("biologicaOrganism").getCharacteristic("wings") === "Wings";
      impossibleTask = vars.offspringHasWings ? "no wings" : "wings";
      GG.tasksController.set('currentTask.targetDrake', impossibleTask);
      return runAndWait("Submit offspring", 200, function() {
        return $('.offspring-buttons-use').click();
      }, function() {
        var speechText, successText;
        expect($('.speech-bubble-no-npc:not(.hidden)').length).toBe(1);
        speechText = $('.speech-bubble-no-npc:not(.hidden)').html();
        successText = GG.tasksController.get('currentTask.npc.speech.completionText').replace(/<br\/>/g, "<br>");
        return expect(speechText.indexOf(successText)).toBe(-1);
      });
    });
    it("should get a success message if they submit a correct drake", function() {
      return runAndWait("Click ok", 200, function() {
        return $('.speech-bubble-no-npc:not(.hidden) button').click();
      }, function() {
        var possibleTask;
        expect($('.speech-bubble-no-npc:not(.hidden)').length).toBe(0);
        vars.offspringHasWings = GG.breedingController.get('child').get("biologicaOrganism").getCharacteristic("wings") === "Wings";
        possibleTask = vars.offspringHasWings ? "wings" : "no wings";
        GG.tasksController.set('currentTask.targetDrake', possibleTask);
        return runAndWait("Submit offspring", 200, function() {
          return $('.offspring-buttons-use').click();
        }, function() {
          var speechText, successText;
          expect($('.speech-bubble-no-npc:not(.hidden)').length).toBe(1);
          speechText = $('.speech-bubble-no-npc:not(.hidden)').html();
          successText = GG.tasksController.get('currentTask.npc.speech.completionText').replace(/<br\/>/g, "<br>");
          return expect(speechText.indexOf(successText)).toBeGreaterThan(0);
        });
      });
    });
    return it("should go back to the town after they dismiss the success message", function() {
      expect($('.npc .bubble:not(.hidden)').length).toBe(0);
      return runAndWait("Click ok", 1500, function() {
        return $('.speech-bubble-no-npc:not(.hidden) button').click();
      }, function() {
        expect(parseInt($('#breeding-apparatus').css('left'))).toBeGreaterThan(1000);
        return expect($('.npc .bubble:not(.hidden)').length).toBe(1);
      });
    });
  });

}).call(this);
