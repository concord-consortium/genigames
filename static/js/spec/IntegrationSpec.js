(function() {

  describe("Integration", function() {
    var flag, runAndWait;
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
    return it("should be able to behave like a student", function() {
      var offspringParentSex, pool;
      this.after(function() {
        console.log("running after");
        return $('#container').hide();
      });
      runAndWait("Pause", 1000, function() {
        return console.log('waiting for load');
      }, function() {
        return expect(GG.townsController.get('currentTown')).toBe(null);
      });
      runAndWait("Castle should be clicked", 5000, function() {
        return Ember.run(function() {
          return $('.castle').click();
        });
      }, function() {
        expect($('#world').length).toBe(0);
        expect($('#town').length).toBe(1);
        return expect(GG.townsController.get('currentTown')).toBe(GG.townsController.get('content')[0]);
      });
      runAndWait("Question bubble should be clicked", 200, function() {
        return Ember.run(function() {
          return $('.npc a img:not(.hidden)').click();
        });
      }, function() {
        expect($('.npc a img:not(.hidden)').length).toBe(0);
        return expect($('.npc .speech-bubble:not(.hidden)').length).toBe(1);
      });
      runAndWait("Task should be accepted, breeding machine should load", 3000, function() {
        return Ember.run(function() {
          return $('.npc .speech-bubble:not(.hidden) button:contains("Ok")')[0].click();
        });
      }, function() {
        expect($('.npc .speech-bubble:not(.hidden)').length).toBe(0);
        expect($('.heart-bubble:not(.hidden)').length).toBe(0);
        expect($('.npc a img:not(.hidden)').length).toBe(0);
        expect($('#breed-button.enabled').length).toBe(0);
        expect(GG.tasksController.get('currentTask')).toBe(GG.tasksController.get('content')[0]);
        expect(GG.parentController.get('selectedMother')).toBe(null);
        expect(GG.parentController.get('selectedFather')).toBe(null);
        expect(GG.parentController.get('content').length).toBe(4);
        expect($('#parent-fathers-pool-container .chromosome-panel.hidden').length).toBe(1);
        expect($('#parent-mothers-pool-container .chromosome-panel.hidden').length).toBe(1);
        expect(GG.breedingController.get('child')).toBe(null);
        return expect(GG.moveController.get('moves')).toBe(0);
      });
      runAndWait("Mother should be selectable", 500, function() {
        return Ember.run(function() {
          var parents;
          parents = $('#parent-mothers-pool-container .parent img');
          expect(parents.length).toBe(2);
          return parents[0].click();
        });
      }, function() {
        expect(GG.parentController.get('selectedMother')).toNotBe(null);
        return expect($('#breed-button.enabled').length).toBe(0);
      });
      runAndWait("Father should be selectable", 500, function() {
        return Ember.run(function() {
          var parents;
          parents = $('#parent-fathers-pool-container .parent img');
          expect(parents.length).toBe(2);
          return parents[0].click();
        });
      }, function() {
        expect(GG.parentController.get('selectedFather')).toNotBe(null);
        return expect($('#breed-button.enabled').length).toBe(1);
      });
      runAndWait("Chromosome panels should be expandable", 2200, function() {
        return Ember.run(function() {
          var ex, _i, _len, _ref, _results;
          _ref = $('.expander');
          _results = [];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            ex = _ref[_i];
            _results.push(ex.click());
          }
          return _results;
        });
      }, function() {
        expect($('#parent-fathers-pool-container .chromosome-panel:not(.hidden)').length).toBe(1);
        return expect($('#parent-mothers-pool-container .chromosome-panel:not(.hidden)').length).toBe(1);
      });
      runAndWait("Chromosome panels should be collapsible", 2200, function() {
        return Ember.run(function() {
          var ex, _i, _len, _ref, _results;
          _ref = $('.expander');
          _results = [];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            ex = _ref[_i];
            _results.push(ex.click());
          }
          return _results;
        });
      }, function() {
        expect($('#parent-fathers-pool-container .chromosome-panel.hidden').length).toBe(1);
        return expect($('#parent-mothers-pool-container .chromosome-panel.hidden').length).toBe(1);
      });
      runAndWait("Breeding should be successful", 2000, function() {
        return Ember.run(function() {
          return $('#breed-button.enabled')[0].click();
        });
      }, function() {
        expect(GG.breedingController.get('child')).toNotBe(null);
        expect(GG.offspringController.get('content').length).toBe(1);
        return expect(GG.moveController.get('moves')).toBe(1);
      });
      offspringParentSex = null;
      runAndWait("Offspring can be moved to the parent pool", 400, function() {
        offspringParentSex = GG.breedingController.getPath('child.sex');
        return $('#offspring-pool .offspring img').click();
      }, function() {
        expect(GG.parentController.get('content').length).toBe(5);
        expect(GG.offspringController.get('content').length).toBe(0);
        return expect(GG.moveController.get('moves')).toBe(2);
      });
      pool = "";
      runAndWait("Offspring can be used to breed", 2000, function() {
        pool = offspringParentSex === GG.MALE ? "#parent-fathers-pool-container" : "#parent-mothers-pool-container";
        $(pool + " .parent img")[2].click();
        return $('#breed-button').click();
      }, function() {
        expect(GG.breedingController.get('child')).toNotBe(null);
        expect(GG.offspringController.get('content').length).toBe(1);
        return expect(GG.moveController.get('moves')).toBe(3);
      });
      runAndWait("Offspring parent can be removed from the parent pool", 200, function() {
        return $(pool + " .parent .removeButton").click();
      }, function() {
        var sel;
        expect(GG.parentController.get('content').length).toBe(4);
        sel = offspringParentSex === GG.MALE ? 'selectedFather' : 'selectedMother';
        expect(GG.parentController.get(sel)).toBe(null);
        return expect($(pool + " .parent .removeButton").length).toBe(0);
      });
      runs(function() {
        flag = false;
        Ember.run(function() {
          var ex, _i, _len, _ref, _results;
          _ref = $('.expander');
          _results = [];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            ex = _ref[_i];
            _results.push(ex.click());
          }
          return _results;
        });
        return GenGWT.generateAliveDragonWithAlleleStringAndSex("a:w,b:w,a:D", GG.FEMALE, function(org) {
          var drake;
          drake = GG.Drake.createFromBiologicaOrganism(org);
          Ember.run(function() {
            GG.parentController.pushObject(drake);
            return GG.parentController.selectMother(drake);
          });
          return GenGWT.generateAliveDragonWithAlleleStringAndSex("a:w,b:w,a:D", GG.MALE, function(org) {
            drake = GG.Drake.createFromBiologicaOrganism(org);
            Ember.run(function() {
              GG.parentController.pushObject(drake);
              return GG.parentController.selectFather(drake);
            });
            GG.breedingController.breedDrake();
            return setTimeout(function() {
              return flag = true;
            }, 3000);
          });
        });
      });
      waitsFor(function() {
        return flag;
      }, "Should (stubbed out) breed the correct drake", 5500);
      runAndWait("Click ok to complete the task", 3000, function() {
        expect($('.npc .speech-bubble:not(.hidden)').length).toBe(1);
        return $('.npc .speech-bubble:not(.hidden) button:contains("Ok")').click();
      }, function() {
        expect($('.heart-bubble:not(.hidden)').length).toBe(1);
        expect($('.npc .speech-bubble:not(.hidden)').length).toBe(0);
        expect($('.npc a img:not(.hidden)').length).toBe(1);
        expect($('#breeding-apparatus').css('top')).toBe('-850px');
        expect($('#parent-fathers-pool-container .chromosome-panel.hidden').length).toBe(1);
        return expect($('#parent-mothers-pool-container .chromosome-panel.hidden').length).toBe(1);
      });
      runAndWait("Question bubble should be clicked", 200, function() {
        return Ember.run(function() {
          return $('.npc a img:not(.hidden)').click();
        });
      }, function() {
        expect($('.npc a img:not(.hidden)').length).toBe(0);
        return expect($('.npc .speech-bubble:not(.hidden)').length).toBe(1);
      });
      runAndWait("Task should be rejected", 3000, function() {
        return Ember.run(function() {
          return $('.npc .speech-bubble:not(.hidden) button:contains("Maybe later")')[0].click();
        });
      }, function() {
        expect($('.npc .speech-bubble:not(.hidden)').length).toBe(0);
        return expect($('.npc a img:not(.hidden)').length).toBe(1);
      });
      runAndWait("Question bubble should be clicked again", 200, function() {
        return Ember.run(function() {
          return $('.npc a img:not(.hidden)').click();
        });
      }, function() {
        expect($('.npc a img:not(.hidden)').length).toBe(0);
        return expect($('.npc .speech-bubble:not(.hidden)').length).toBe(1);
      });
      runAndWait("Task should be accepted, breeding machine should load", 3000, function() {
        return Ember.run(function() {
          return $('.npc .speech-bubble:not(.hidden) button:contains("Ok")')[0].click();
        });
      }, function() {
        expect($('.npc .speech-bubble:not(.hidden)').length).toBe(0);
        expect($('.heart-bubble:not(.hidden)').length).toBe(1);
        expect($('.npc a img:not(.hidden)').length).toBe(0);
        expect($('#breed-button.enabled').length).toBe(0);
        expect(GG.tasksController.get('currentTask')).toBe(GG.tasksController.get('content')[1]);
        expect(GG.parentController.get('selectedMother')).toBe(null);
        expect(GG.parentController.get('selectedFather')).toBe(null);
        expect(GG.parentController.get('content').length).toBe(4);
        expect($('#parent-fathers-pool-container .chromosome-panel.hidden').length).toBe(1);
        expect($('#parent-mothers-pool-container .chromosome-panel.hidden').length).toBe(1);
        expect(GG.breedingController.get('child')).toBe(null);
        return expect(GG.moveController.get('moves')).toBe(0);
      });
      runs(function() {
        flag = false;
        return GenGWT.generateAliveDragonWithAlleleStringAndSex("a:w,b:w,a:hl,b:hl,a:D", GG.FEMALE, function(org) {
          var drake;
          drake = GG.Drake.createFromBiologicaOrganism(org);
          Ember.run(function() {
            GG.parentController.pushObject(drake);
            return GG.parentController.selectMother(drake);
          });
          return GenGWT.generateAliveDragonWithAlleleStringAndSex("a:w,b:w,a:hl,b:hl,a:D", GG.MALE, function(org) {
            drake = GG.Drake.createFromBiologicaOrganism(org);
            Ember.run(function() {
              GG.parentController.pushObject(drake);
              return GG.parentController.selectFather(drake);
            });
            return setTimeout(function() {
              return flag = true;
            }, 3000);
          });
        });
      });
      waitsFor(function() {
        return flag;
      }, "Should (stubbed out) set up the correct parents", 5500);
      runAndWait("Should increment goal counter", 3000, function() {
        expect($('.match-count').text()).toBe("0");
        expect($('.target-count').text()).toBe("3");
        return $('#breed-button').click();
      }, function() {
        return expect($('.match-count').text()).toBe("1");
      });
      runAndWait("Should increment goal counter again", 3000, function() {
        expect($('.target-count').text()).toBe("3");
        return $('#breed-button').click();
      }, function() {
        return expect($('.match-count').text()).toBe("2");
      });
      runAndWait("Should increment goal counter again and complete task", 3000, function() {
        expect($('.target-count').text()).toBe("3");
        return $('#breed-button').click();
      }, function() {
        return expect($('.match-count').text()).toBe("3");
      });
      runAndWait("Click ok to complete the task", 3000, function() {
        expect($('.npc .speech-bubble:not(.hidden)').length).toBe(1);
        return $('.npc .speech-bubble:not(.hidden) button:contains("Ok")').click();
      }, function() {
        expect($('#town').length).toBe(0);
        return expect($('#world').length).toBe(1);
      });
      runAndWait("Huts should be clicked", 8000, function() {
        return Ember.run(function() {
          return $('.huts').click();
        });
      }, function() {
        expect($('#world').length).toBe(0);
        expect($('#town').length).toBe(1);
        return expect(GG.townsController.get('currentTown')).toBe(GG.townsController.get('content')[1]);
      });
      runAndWait("Question bubble should be clicked", 200, function() {
        return Ember.run(function() {
          return $('.npc a img:not(.hidden)').click();
        });
      }, function() {
        expect($('.npc a img:not(.hidden)').length).toBe(0);
        return expect($('.npc .speech-bubble:not(.hidden)').length).toBe(1);
      });
      runAndWait("Task should be accepted, breeding machine should load", 3000, function() {
        return Ember.run(function() {
          return $('.npc .speech-bubble:not(.hidden) button:contains("Ok")')[0].click();
        });
      }, function() {
        expect($('.npc .speech-bubble:not(.hidden)').length).toBe(0);
        expect($('.heart-bubble:not(.hidden)').length).toBe(0);
        expect($('.npc a img:not(.hidden)').length).toBe(0);
        expect($('#breed-button.enabled').length).toBe(0);
        expect(GG.tasksController.get('currentTask')).toBe(GG.tasksController.get('content')[0]);
        expect(GG.parentController.get('selectedMother')).toBe(null);
        expect(GG.parentController.get('selectedFather')).toBe(null);
        expect(GG.parentController.get('content').length).toBe(4);
        expect($('#parent-fathers-pool-container .chromosome-panel.hidden').length).toBe(1);
        expect($('#parent-mothers-pool-container .chromosome-panel.hidden').length).toBe(1);
        expect(GG.breedingController.get('child')).toBe(null);
        return expect(GG.moveController.get('moves')).toBe(0);
      });
      runs(function() {
        flag = false;
        return GenGWT.generateAliveDragonWithAlleleStringAndSex("a:w,b:w,a:D", GG.FEMALE, function(org) {
          var drake;
          drake = GG.Drake.createFromBiologicaOrganism(org);
          Ember.run(function() {
            GG.parentController.pushObject(drake);
            return GG.parentController.selectMother(drake);
          });
          return GenGWT.generateAliveDragonWithAlleleStringAndSex("a:w,b:w,a:D", GG.MALE, function(org) {
            drake = GG.Drake.createFromBiologicaOrganism(org);
            Ember.run(function() {
              GG.parentController.pushObject(drake);
              return GG.parentController.selectFather(drake);
            });
            return setTimeout(function() {
              return flag = true;
            }, 3000);
          });
        });
      });
      waitsFor(function() {
        return flag;
      }, "Should (stubbed out) set up the correct parents", 5500);
      runAndWait("Should breed and complete the task", 3000, function() {
        return $('#breed-button').click();
      }, function() {
        return expect($('.npc .speech-bubble:not(.hidden)').length).toBe(1);
      });
      return runAndWait("Click ok to complete the task", 3000, function() {
        return $('.npc .speech-bubble:not(.hidden) button:contains("Ok")').click();
      }, function() {
        expect($('#town').length).toBe(0);
        return expect($('#world').length).toBe(1);
      });
    });
  });

}).call(this);
