% main.m
% 
% Controls overall functionality of the program.
%
% Authors: Stephen Hannon

clear

%% set constants

%DEBUG = true; % if true, output detailed debugging logs for each run

pickerAlg = @naivePicker; % which algorithm to test. Either naivePicker or fastPicker.
                          % The @ sign is needed to create a function handle

ITERATIONS = 10; % number of times to run through (seconds)

config.CALL_FREQUENCY = 0.2; % average number of calls per iteration (between 0 and 1)
config.NUM_FLOORS = 5;
config.NUM_CARS = 2;
config.FLOOR_HEIGHT = 1; % m
config.BOARDING_TIME = 1; % time elevator doors stay open for boarding (s)
config.MAX_VELOCITY = 10; % m/s
config.ACCELERATION = 1.5; % m/s^2

%% set variables

passengers = struct();
cars = struct();

numDroppedOff = 0; % number of passengers successfully dropped off
numPickedUp = 0; % passengers currently in an elevator
numWaiting = 0; % passengers waiting for an elevator to arrive

for icar = 1:config.NUM_CARS
    cars(icar).y = randi(config.NUM_FLOORS) * config.FLOOR_HEIGHT; % position of TOP of car
    cars(icar).velocity = 0;
    cars(icar).doorsOpen = false;
    cars(icar).destinations = []; % Next floors this car wants to travel to.
                                  % First number goes first, and so on.
    cars(icar).timeRemaining = 0; % how long to wait before it can leave
end

%% run simulation

for it = 1:ITERATIONS
    msg(['--- t = ', num2str(it), ' ---']);
    
    if it == 1 || rand() < config.CALL_FREQUENCY % always make a call the first time through
        call = makeRandCall(config.NUM_FLOORS);
        numWaiting = numWaiting + 1;
        
        % The picker can't know the destination, just the direction (up/down).
        % This limitation keeps it more realistic.
        callSanitized.fromFloor = call.fromFloor;
        callSanitized.direction = call.direction;
    
        [responder, scores] = pickerAlg(it, config, cars, callSanitized);
        cars(responder).destinations = [cars(responder).destinations, call.fromFloor];
        % TODO: let pickerAlg change the destination queue
        
        msg(['new call from ', num2str(call.fromFloor), ' to ',...
            num2str(call.toFloor), ', taken by car ', num2str(responder)]);
        msg(['Car scores: ', num2str(scores)]);
        
        % add data to passengers struct array
        passengers(end+1).startTime = it;
        passengers(end).fromFloor = call.fromFloor;
        passengers(end).toFloor = call.toFloor;
        passengers(end).responder = responder;
        passengers(end).pickedUp = false;
        passengers(end).droppedOff = false;
    else
        msg('No call made');
    end
    
    % --- update all elevator positions ---
    for icar = 1:config.NUM_CARS
        car = cars(icar);
        msg(['CAR ', num2str(icar), ':']);
        
        % If the car still has to wait, don't call updateY. Instead,
        % decrement the time the car has to remain waiting
        if car.timeRemaining > 0
            msg(['  Waiting for ', num2str(cars(icar).timeRemaining), ' more second(s)']);
            cars(icar).timeRemaining = car.timeRemaining - 1;
        else
            [cars(icar).y, cars(icar).velocity] = updateY(config, car);
            msg(['  to y = ', num2str(car.y)]);
        end
        
        
        % if car is stopped at a floor that is a destination
        if car.velocity == 0 && ismember(car.y, car.destinations * config.FLOOR_HEIGHT)
            msg(['  arrived at y = ', num2str(car.y)]);
            
            % adjust the relevant passenger struct(s)
            % start at 2 because the first is empty
            for ipass = 2:length(passengers)
                if passengers(ipass).pickedUp % drop passenger off
                    if passengers(ipass).toFloor * config.FLOOR_HEIGHT == car.y
                        numDroppedOff = numDroppedOff + 1;
                        numPickedUp = numPickedUp - 1;
                        disp(numPickedUp);
                        
                        passengers(ipass).droppedOff = true;
                        passengers(ipass).dropOffTime = it;
                        passengers(ipass).totalTime = it - passengers(ipass).startTime;
                        
                        msg(['  dropped off passenger ', num2str(ipass-1),...
                            '. Total waiting time: ', num2str(passengers(ipass).totalTime)]);
                        
                        % add new destination to queue and remove current floor
                        toFiltered = cars(icar).destinations ~= passengers(ipass).toFloor;
                        cars(icar).destinations = cars(icar).destinations(toFiltered);
                        
                        cars(icar).timeRemaining = config.BOARDING_TIME;
                    end
                else % pick passenger up
                    if passengers(ipass).fromFloor * config.FLOOR_HEIGHT == car.y
                        numPickedUp = numPickedUp + 1;
                        numWaiting = numWaiting - 1;
                        disp(numPickedUp);
                        
                        msg(['  picked up passenger ', num2str(ipass-1)]);
                        
                        passengers(ipass).pickedUp = true;
                        passengers(ipass).pickUpTime = it;
                        passengers(ipass).pickUpCar = icar;
                        
                        % add new destination to queue and remove current floor
                        fromFiltered = cars(icar).destinations ~= passengers(ipass).fromFloor;
                        cars(icar).destinations = [passengers(ipass).toFloor,...
                            cars(icar).destinations(fromFiltered)];
                        
                        cars(icar).timeRemaining = config.BOARDING_TIME;
                    end
                end
            end % end for
        end
        
        msg(['  destinations: ', num2str(cars(icar).destinations)]);
    end
    
end

%% display statistics

msg(' ');
disp('----- END OF RUN -----');
disp(['Iterations: ', num2str(ITERATIONS)]);
disp(['Total passengers: ', num2str(length(passengers) - 1)]);
disp(['  Passengers waiting for car: ', num2str(numWaiting)]);
disp(['  Passengers riding elevator: ', num2str(numPickedUp)]);
disp(['  Passengers dropped off:     ', num2str(numDroppedOff)]);

function msg(message)
    DEBUG = true;
    if DEBUG
        disp(message);
    end
end
