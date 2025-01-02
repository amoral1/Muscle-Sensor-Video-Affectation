import http.requests.*;
int water_level;

void setup() {

  size(400, 400);
  smooth();	
  //println("Reponse Content-Length Header: " + get.getHeader("Content-Length"));
}

void draw() {
  if (mousePressed) { //this is the if statement that treats things like like buttons, the diff between events & variable //
    GetRequest get = new GetRequest("https://api.particle.io/v1/devices/e00fce68e73a1f346d7f8ac3/water_value?access_token=2ec797d127a015068794dadc739d04b325510443");
    get.send();
    JSONObject response = parseJSONObject(get.getContent());    
    water_level = response.getInt("result");    // variable set to speak to particle's 'variable', presumably
    println(water_level);
  }
}
/*
void draw(){
 text( variable(GetRequest), 10, 500);
 }
 */
