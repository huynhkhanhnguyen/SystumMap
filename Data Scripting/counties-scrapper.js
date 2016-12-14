let fs = require('fs');
var async = require("async");
let request = require('request');
let CACounties = __dirname + '/CaliforniaCounties.txt';
let jsonfile = require('jsonfile')

function crawData() {
  let queryBaseUrl = 'http://nominatim.openstreetmap.org/search.php?q=';
  let subfixUrl = '&polygon=1&format=json';
  let counties = fs.readFileSync(CACounties).toString().trim().split('\n');

  console.log('start request...')
  async.eachSeries(counties, function (county, done) {
    let countyUrl = county.replace(' ', '%20');
    let url = queryBaseUrl + countyUrl + subfixUrl;
    console.log('County ' + county);

    request(url, function (error, response, body) {
      if (!error && response.statusCode == 200) {
        console.log('request data for county ' + county + ' success');
        let result = JSON.parse(body);
        let dataExist = false;
        for (index in result) {
          if(result[index].class == 'boundary' && result[index].type == 'administrative') {
            console.log('write data to file');
            let fileName = county.split(' ').join('') + '.json';
            jsonfile.writeFile("./crawled-data/" + fileName, result[index]);
            dataExist = true;
            break;
          }
        }
        if (!dataExist) {
          fs.appendFile('result.txt', counties[countyIndex] + ' not exist' , function (err) { });
        }
      }
      done();
    });
  }, function () {
    console.log('finished!')
  });
}

crawData();
