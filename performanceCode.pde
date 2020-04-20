/*
TO DO: 
reference all borrowed code through links and coder name
comment descriptivly on big functions/chunks of code
commentate per line on "special" or "strange" code

Title: Every other way this could have gone
Artist: Batool Desouky
Year: 2019
Produced for the MA/MFA in Computational Arts, year 2018/19

Brief description:
This code is one of three programmes that make up the artwork, and one of the two programmes that run the performance part of the artwork.
This programme communicates with an arduino programme through serial communication, sending back and forth data that triggers different 
components on both sides.

The code reads from an external txt file, listens from inputs from the capcitive touch sensors connected through arduino, applies a set of logical exicutions
to the content of the txt file, and outputs strings that are printed through the arduino controlled thermal printer. 

Stories used are public domain translations of Aesops fables, sourced from Project Gutenberg: https://www.gutenberg.org/files/11339/11339-h/11339-h.htm 

At the core of the code is a Lexicographical ordering algorithm, that is conceptually based on the mathematical concept of "Possibility Space".
Help for building the code:
https://www.geeksforgeeks.org/print-all-combinations-of-given-length/
https://medium.com/@rwillt/two-very-different-algorithms-for-generating-permutations-412e8cc0039c 
https://www.quora.com/How-would-you-explain-an-algorithm-that-generates-permutations-using-lexicographic-ordering

some code is borrowed from a tutorial by Daniel Shiffman, link to tutorial below:
https://www.youtube.com/watch?v=goUlyp4rwiU

This guide was referenced to pass long strings of data to arduino:
https://sspog.wordpress.com/code-examples/processing-to-arduino-strings-bigger-than-64-bytes/

*/
import processing.serial.*; //import the Serial library
Serial myPort; 

String val;                     //this is the string of values coming from arduino
int [] vals = {0, 1, 2, 3};     //this is the main array of values that the programme runs on. Shuffling these shuffles the texts


int load;                       //variable for holding button value from capacative sensor no. 1. prints the original story
int permute;                    //generates (and prints the next permutation of the story 
int index;                      //holds the the order of numbers in the vals array, acting as an index identifyier of the current permutation

String [] File;                 //read from external txt file. will save each line as a seperate index in an array
String file;                    //join all content of the file into one srting
String [] lines;
String l; 
String s;
String toPrint;

int storyNum = 0;
int scroll;

PFont f; 
String[] Stories = {"The Astronomer.txt", "The Belly and the Members.txt", "The Old Man and Death.txt", "The Wind and The Sun.txt"}; //src files of original stories to read from 
boolean firstContact = false; //boolean to check that both programmes are communicating

void setup() {
  //size(400, 400);            //uncomment for window mode
  fullScreen();                //comment out to exist fullscreen mode
  printArray(Serial.list());
  myPort = new Serial(this, Serial.list()[2], 9600);
  myPort.bufferUntil('\n');                           //buffer in comming data until the end of a "line" 

  File = loadStrings(Stories[storyNum]);
  file = join(File, " ");                             //file is the baseline object
  lines = splitTokens(file, "#");                     //seperate parts of the story in clear chunks using an uncommon text character
  printArray(lines);

  f = createFont("Bungee outline", 45);

  load = 0;
  permute = 0;
  index = 0;

  scroll = 0; 
  
  noLoop();  //control the progression of the code manually. noLoop() stops the draw function from automatically looping
}

void draw() {
  generate();
  background(0);
  textFont(f);
  textAlign(LEFT, TOP);
  text(s + "\n" + toPrint, 5, 25, width - 5, height - 25);
  scroll --;
  
  if (scroll < 0){
   scroll = width; 
  }
}

void serialEvent(Serial myPort) {
  val = myPort.readStringUntil('\n');      //because serial is recieved as printed values, we store them in a strong object

  if (val != null) { //continue ONLY if there is data coming in to our val variable
    val = trim(val);  //remove white space to be able to access values

    print("signal is: ");
    println(val);

    //look for our 'A' string to start the handshake
    //if it's there, clear the buffer, and send a request for data
    if (firstContact == false) {
      if (val.equals("A")) {
        myPort.clear();
        firstContact = true;
        myPort.write("A");
        println("contact");
      }
    } else {                           //if we've already established contact, keep getting and parsing data

      if (keyPressed == true) {
        if (key == 'l') { 
          myPort.write(file);        //the first port.write is the original story/file
        } else if (key == 't') {
          myPort.write("test");      //before printing the alternatives, print the alternative no.
          println("test");
        } else if (key == 'g') {     //print the alternative fiction by activating the draw loop where the generate function lives
          redraw();
          myPort.write(s);
          delay(500);                //wait before sending next combo to avoid printing 2 at once
        }
      }

      int [] allSignals = int(splitTokens(val, ",")); //since we are receiving a string of more than one kind of data, we store it in an array to be able to singal out data from which sensor button and use them seperately.
      printArray(allSignals);
      if (allSignals.length == 4) {    //if you receive ALL intended data
        load = allSignals[0];          //these asignment have to come after establishing contact to avoid a null pointer
        permute = allSignals[1];
        index = allSignals[2];
      }
      println("load: " + load + " pemute: " + permute + " draw: " + index);

      if (load == 1) {              //first we need a print out of the original story. the file string object read from the txt file
        myPort.write(file);
        print(file);
        delay(500);
      } else if (permute == 1) {      //when we are ready to recieve a perumutation
        redraw();
        myPort.write(toPrint);
        delay(9000);                  //delay needs to last one full story
        println(toPrint);
      } else if (index == 1) {        //for printing out the current index (order of the main array) to keep track of where we are in the possibility space of permutations
        myPort.write(s + "\n");
      }
    }
  }
}

void generate() {

  //----Sorting code
  //STEP 1
  int largestI = -1;
  for (int i = 0; i < vals.length - 1; i++) {
    if (vals[i] < vals[i + 1]) {
      largestI = i;
    }
  }
  if (largestI == -1) {
    noLoop();
    println("-1 reached");
  }
  
  //STEP 2
  int largestJ = -1;
  for (int j = 0; j < vals.length; j ++) {
    if (vals[largestI] < vals[j]) {
      largestJ = j;
    }
  }
  
  //STEP 3
  swap(vals, largestI, largestJ);
  
  //STEP 4: reverse from the largest I + 1 to the end
  int size = vals.length - largestI - 1;
  int[] endArray = new int[size];
  arrayCopy(vals, largestI + 1, endArray, 0, size);
  endArray = reverse(endArray);
  arrayCopy(endArray, 0, vals, largestI + 1, size);
  //----end of sorting code

  s = " ";                                                  //must be emptied before every new combo is generated
  l = " ";                                                  //must be emptied before every new combo is generated
  for (int i = 0; i < vals.length; i++) {
    s += vals[i];
    l += lines[vals[i]];
  }
  
  toPrint = l + " end.";

  fill(255);
  text(toPrint, 10, 100);
}
//MATCH WITH STEP 3
void swap (int[] a, int i, int j) {
  int temp = a[i];
  a[i] = a[j];
  a[j] = temp;
}
