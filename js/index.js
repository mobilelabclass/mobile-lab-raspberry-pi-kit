var wpi = require('wiringpi-node');
var bleno = require('bleno');

// bleno modules
var PrimaryService = bleno.PrimaryService;
var Characteristic = bleno.Characteristic;
var Descriptor = bleno.Descriptor;

// Give our Raspberry Pi a unique identifier
var name = 'My Awesome Servo';

// Get your own UUIDs at https://www.uuidgenerator.net/
var deviceUuid = '269e0082-be19-4e59-9f77-af341b57e1bf';
var serviceUuid = 'e853db91-e787-4eeb-ae7c-536d689f5741';
var characteristicUuid = '01ad6336-32b5-499c-9130-3f989684044c';

var MAX_PULSE = 200;
var MIN_PULSE = 100;
var delay = 20;
var direction = 1;
var pulse = 100;


/**
 * Servo setup
 */
wpi.wiringPiSetupGpio();
wpi.wiringPiSetupGpio();
wpi.pinMode(18, wpi.PWM_OUTPUT)
wpi.pwmSetMode(wpi.PWM_MODE_MS)
wpi.pwmSetClock(192)
wpi.pwmSetRange(2000)


/**
 * BLE setup
 */

// Set a custom device name
// by setting the BLENO_DEVICE_NAME environment variable:
process.env.BLENO_DEVICE_NAME = name;

// Apple recommended interval
// process.env.BLENO_ADVERTISING_INTERVAL = 20;

/**
 * Define our servo service
 */
var myServoService = new PrimaryService({
  uuid: serviceUuid,

  characteristics: [
    new Characteristic({
      uuid: characteristicUuid,
      properties: ['read', 'write'],
      descriptors: [
        new bleno.Descriptor({
          uuid: characteristicUuid,
          value: 'servo position'
        })
      ],
      onWriteRequest: function(data, offset, withoutResponse, callback) {
        // https://nodejs.org/api/buffer.html
    if (data) {
      console.log('>>> offset', offset);
      var value = data.readInt8(offset);
      console.log('>> Received BLE write request:', value);
      // convert value to pulse
      var pulseRange = MAX_PULSE - MIN_PULSE;
      var pulse = Math.round(MIN_PULSE + (value / 100) * pulseRange);
      console.log('>> Writing pulsetoservo', pulse);
      wpi.pwmWrite(18, pulse);

    
    }

    var result = Characteristic.RESULT_SUCCESS;
    callback(result);
      }
    })
  ]

});

bleno.setServices([
  myServoService
]);

/**
 * State changes
 */
bleno.on('stateChange', function(newState) {
  console.log('bleno state changed:', newState); 
  
   if (newState === 'poweredOn') {
      bleno.startAdvertising( name, [deviceUuid] ); 
   } else {
     bleno.stopAdvertising();
   }

});

/**
 * Start advertising BLE device
 */
bleno.on('advertisingStart', function(err) {
  if (!err) {
      console.log('Started advertising with uuid', deviceUuid);

  } else {
    console.log('Error advertising our BLE device!', err);
  }
});

