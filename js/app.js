(function() {
  var GG;

  window.GG = GG = Ember.Application.create();

  GG.Drake = Ember.Object.extend({
    gOrg: null,
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
        return GenGWT.breedDragon(this.get('mother').gOrg, this.get('father').gOrg, function(gOrg) {
          var drake;
          drake = GG.Drake.create({
            imageURL: gOrg.imageURL,
            sex: gOrg.sex,
            gOrg: gOrg
          });
          GG.breedingController.set('child', drake);
          return GG.offspringController.pushObject(drake);
        });
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
      var drake, whichParent;
      drake = this.get('content');
      if (this.clickToBecomeParent) {
        whichParent = drake.get('sex') === 0 ? 'selectedMother' : 'selectedFather';
        return GG.parentController.set(whichParent, drake);
      }
    }
  });

  $(function() {
    return setTimeout(function() {
      var i, _results;
      _results = [];
      for (i = 0; i <= 3; i++) {
        _results.push(GenGWT.generateAliveDragonWithSex(i % 2, function(gOrg) {
          var drake;
          drake = GG.Drake.create({
            imageURL: gOrg.imageURL,
            sex: gOrg.sex,
            gOrg: gOrg
          });
          return GG.parentController.pushObject(drake);
        }));
      }
      return _results;
    }, 500);
  });

}).call(this);
