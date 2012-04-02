GG = Ember.Application.create();

GG.Drake = Ember.Object.extend({
  gOrg: null,      // organism object created by GWT
  sex: null,
  imageURL: null
});

GG.parentController = Ember.ArrayProxy.create({
  content: [],
  selectedMother: null,
  selectedFather: null
});

GG.offspringController = Ember.ArrayProxy.create({
  content: []
});

GG.breedingController = Ember.Object.create({
  motherBinding: 'GG.parentController.selectedMother',
  fatherBinding: 'GG.parentController.selectedFather',
  child: null,
  breedDrake: function() {
    if (this.get('mother') && this.get('father')) {
      GenGWT.breedDragon(this.get('mother').gOrg, this.get('father').gOrg, function(gOrg) {
        var drake = GG.Drake.create({
          imageURL: gOrg.imageURL,
          sex: gOrg.sex,
          gOrg: gOrg
        });
        GG.breedingController.set('child', drake);
        GG.offspringController.pushObject(drake);
      })
    }
  }
});

GG.DrakeView = Ember.View.extend({
  tagName: 'img',
  attributeBindings: ['src', 'width'],
  srcBinding: 'content.imageURL',
  width: 200,
  clickToBecomeParent: false,
  click: function(evt) {
    var drake = this.get('content');
    if (this.clickToBecomeParent) {
      console.log("click!")
      var whichParent = (drake.get('sex') === 0) ? 'selectedMother' : 'selectedFather';
      GG.parentController.set(whichParent, drake);
    }
  }
});

// initialize stuff at start
$(function () {
  // create initial parents, after waiting half a second for GWT to load
  setTimeout(function() {
    for (i = 0; i < 4; i++) {
      GenGWT.generateAliveDragonWithSex(i%2, function(gOrg) {
        var drake = GG.Drake.create({
          imageURL: gOrg.imageURL,
          sex: gOrg.sex,
          gOrg: gOrg
        });
        GG.parentController.pushObject(drake);
      });
    }
  }, 500);
});