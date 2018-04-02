function [newY, newV] = updateY(car)
% Parameters:
%  
%
% Return:
%  newY (number between 1 and NUM_FLOORS)
%  newV (number): new velocity of car (negative is down)
% 
% Authors: 
    
    newY = car.y;
    
    if ~isempty(car.destinations)
        if car.destinations(1) > car.y % head up
            newY = car.y + 1;
            newV = 1;
        elseif car.destinations(1) < car.y % head down
            newY = car.y - 1;
            newV = -1;
        else % stop
            newV = 0;
        end
    else
        newV = 0;
    end
end