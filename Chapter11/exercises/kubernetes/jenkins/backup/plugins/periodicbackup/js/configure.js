Event.observe(window, 'load', function(event) {
    Event.observe($$('form[name=config]')[0], 'submit', checkForm);
});

function checkForm(event) {
    var element = Event.element(event);
    var volumeSize = $$('input[name=volumeSize]')[0];
    var cycleQuantity= $$('input[name=_.cycleQuantity]')[0];
    var cycleDays= $$('input[name=_.cycleDays]')[0];

    if($$('input[name=multiVolume]')[0] != undefined && $$('input[name=multiVolume]')[0].checked) {
        if(!validatePositiveNum(volumeSize.value)) {
            Event.stop(event);
            setDivOpacity('msg3',0);
            $('msg3').style.display="block";
            $('msg3').style.color="red";
            $('msg3').innerHTML = "<strong>Error! Entered split volume threshold is not correct, please correct.</strong>";
            appear('msg3');
        }
        else {
            setDivOpacity('msg3',0);
        }
    }
    if(!validatePositiveNum(cycleQuantity.value)) {
        Event.stop(event);
        setDivOpacity('msg4',0);
        $('msg4').style.display="block";
        $('msg4').style.color="red";
        $('msg4').innerHTML = "<strong>Error! Maximum number of backups is not correct, please correct.</strong>";
        appear('msg4');
    }
    else {
        setDivOpacity('msg4',0);
    }
    if(!validatePositiveNum(cycleDays.value)) {
        Event.stop(event);
        setDivOpacity('msg5',0);
        $('msg5').style.display="block";
        $('msg5').style.color="red";
        $('msg5').innerHTML = "<strong>Error! Number of days is not correct, please correct.</strong>";
        appear('msg5');
    }
    else {
        setDivOpacity('msg5',0);
    }
}

function setDivOpacity(divId, level) {
    $(divId).style.opacity = level;
    $(divId).style.MozOpacity = level;
    $(divId).style.KhtmlOpacity = level;
    $(divId).style.filter = "alpha(opacity=" + (level * 100) + ");";
}

function appear(divId) {
    for (i = 0; i <= 1; i += (1 / 20)) {
        setTimeout("setDivOpacity(" + divId + "," + (i) + ")", i * 1000);
    }
}

//function will return false if value is not numerical or not positive
function validatePositiveNum(value) {
    var number = parseInt(value);
    if(isNaN(number)) {
        return false;
    }
    else {
        if(number > 0) {
            //if parseInt will return number but input was not a number, for example "3fg" -> validation will fail
            if(value.toString() != number.toString()) {
                return false;
            }
            else {
                return true;
            }
        }
        else {
            return false;
        }
    }
}




