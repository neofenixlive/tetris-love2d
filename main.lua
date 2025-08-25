--[[
TetrisLUA project
Coded by NeoFenixLive
================
I put a lot of effort into this. :P
]]

--moves the falling piece
function move_piece(x, y)
    local out_of_bounds, touch_piece = false, false
    
    --moves the piece
    falling_x = falling_x + x
    falling_y = falling_y + y
    
    --checks if its colliding
    for y = 1, 4 do
        for x = 1, 4 do
            if falling[x+((y-1)*4)] ~= 0 then
                --checks if its out of bounds sideways
                if (x+falling_x) > room_width then
                    out_of_bounds = true
                end
                if (x+falling_x) < 1 then
                    out_of_bounds = true
                end
                
                --checks if its touching the ground or a room piece
                if ((y-1)+falling_y) == room_height then
                    out_of_bounds = true
                    touch_piece = true
                end
                if room[x+falling_x+((y-1+falling_y)*room_width)] ~= 0 then
                    out_of_bounds = true
                    touch_piece = true
                end
            end
        end
    end
    
    --reverts the movement
    if out_of_bounds then
        falling_x = falling_x - x
        falling_y = falling_y - y
    end
    
    --places as room piece and makes new falling one
    if touch_piece then
        place_piece(falling, falling_x, falling_y)
        new_piece(game.next_piece, 2, 0)
        game.next_piece = pieces[pieces_list[math.random(1, #pieces_list)]]
    end
end

--rotates the falling piece
function rotate_piece(times)
    local matrix, output = {}, {}
    
    --1d to 2d matrix conversion
    local x, y = 1, 1
    for _, part in ipairs(falling) do
        if not matrix[y] then
            matrix[y] = {}
        end
                        
        matrix[y][x] = part
        x = x + 1
            
        if x > 4 then
            x = 1    
            y = y + 1
        end
    end
    
    for i = 1, times do
        --transposes 2d matrix
        for y = 1, 4 do
            for x = y + 1, 4 do
                matrix[y][x], matrix[x][y] = matrix[x][y], matrix[y][x]
            end
        end
        
        --flips 2d matrix
        for y = 1, 4 do
            local row = matrix[y]
            local left, right = 1, 4
            
            while left < right do
                row[left], row[right] = row[right], row[left]
                left = left + 1
                right = right - 1
            end
        end
    end
    
    --2d to 1d matrix conversion
    for y, _ in ipairs(matrix) do
        for x, __ in ipairs(_) do
            output[x+((y-1)*4)] = matrix[y][x]
        end
    end
    
    --checks if its colliding
    for y = 1, 4 do
        for x = 1, 4 do
            if output[x+((y-1)*4)] ~= 0 then
                if (x+falling_x) > room_width or (x+falling_x) < 1 then
                    return false
                end
                if room[x+falling_x+((y-1+falling_y)*room_width)] ~= 0 then
                    return false
                end
            end
        end
    end
    
    falling = output
end

--creates a falling piece
function new_piece(piece, x, y)
    local new, pos = {}, 0
    
    --copies the template table to falling table
    for _, i in ipairs(piece) do
        new[_] = i
    end
    falling = new
    falling_x = x
    falling_y = y
    
    --checks if its touching something on creation
    for y_check = 1, 4 do
        for x_check = 1, 4 do
            if piece[x_check+((y_check-1)*4)] ~= 0 and room[x+(y*room_width)+pos] ~= 0 then
                --resets the game
                game.current_score = 0
                room = {}
                for i=1, room_width*room_height do
                    table.insert(room, 0)
                end
            end
            pos = pos + 1
        end
        pos = pos + 4
    end
end

--places a piece in room
function place_piece(piece, x_room, y_room)
    local pos = 1
    for y_piece = 1, 4 do
        for x_piece = 1, 4 do
            if piece[x_piece+((y_piece-1)*4)] ~= 0 then
                room[x_room+(y_room*room_width)+pos] = piece[x_piece+((y_piece-1)*4)]
            end
            pos = pos + 1
        end
        pos = pos + 4
    end
end

--checks for full lines
function clear_lines()
    local line_counter, lines_clear = 0, {}
    
    --checks for full lines inside the room
    for pos, piece in ipairs(room) do
        if piece ~= 0 then
            local x, y = 0, 0
            for i = 1, pos, 1 do
                if x >= room_width then
                    x = 1
                    y = y + 1
                else
                    x = x + 1
                end
            end
            
            --counts each part until its the same as room width
            if x == 1 or line_counter > 0 then
                line_counter = line_counter + 1
            end
            if line_counter == room_width then
                table.insert(lines_clear, y)
                line_counter = 0
            end
        else
            line_counter = 0
        end
    end
    
    --clears full lines and moves everything above it
    for _, col in ipairs(lines_clear) do
        for x = 1, room_width do
            room[x+(col*room_width)] = 0
        end
        for y = col, 1, -1 do
            for x = 1, room_width do
                room[x+(y*room_width)] = room[x+((y-1)*room_width)]
            end
        end
    end
    
    --adds points when clearing lines
    if #lines_clear > 0 then
        game.current_score = game.current_score + pieces_points[#lines_clear]
        if game.current_score > game.high_score then
            game.high_score = game.current_score
        end
    end
end

function draw_matrix(matrix, width, offset_x, offset_y)
    for pos, code in ipairs(matrix) do
        if code ~= 0 then
            local x, y = 0, 0
            for i = 1, pos, 1 do
                if x >= width then
                    x = 1
                    y = y + 1
                else
                    x = x + 1
                end
            end
            
            love.graphics.setColor(pieces_colors[code][1], pieces_colors[code][2], pieces_colors[code][3])
            love.graphics.rectangle("fill", (x+offset_x)*40-40, (y+offset_y)*40, 40, 40)
            love.graphics.setColor(0, 0, 0)
            love.graphics.rectangle("line", (x+offset_x)*40-40, (y+offset_y)*40, 40, 40)
        end
    end
end

--================

function love.load()
    --defines pieces parameters
    pieces_list = {"L", "J", "S", "Z", "T", "I", "O"}
    pieces_points = {
        [1]=40,
        [2]=100,
        [3]=300,
        [4]=1200
    }
    pieces_colors = {
        [1]={255,128,0},
        [2]={0,0,255},
        [3]={0,255,0},
        [4]={255,0,0},
        [5]={255,96,96},
        [6]={192,192,255},
        [7]={255,255,0}
    }
    pieces = {
        L=
        {0,1,0,0,
        0,1,0,0,
        0,1,1,0,
        0,0,0,0},
        J=
        {0,0,2,0,
        0,0,2,0,
        0,2,2,0,
        0,0,0,0},
        S=
        {0,0,0,0,
        0,3,3,0,
        3,3,0,0,
        0,0,0,0},
        Z=
        {0,0,0,0,
        0,4,4,0,
        0,0,4,4,
        0,0,0,0},
        T=
        {0,0,0,0,
        0,5,0,0,
        5,5,5,0,
        0,0,0,0},
        I=
        {0,6,0,0,
        0,6,0,0,
        0,6,0,0,
        0,6,0,0},
        O=
        {0,0,0,0
        ,0,7,7,0,
        0,7,7,0,
        0,0,0,0},
    }
    
    --defines room matrix (1d)
    room = {}
    room_width = 8
    room_height = 16
    for i=1, room_width*room_height do
        table.insert(room, 0)
    end
    
    --defines falling / controlling piece
    falling = {}
    falling_x = 0
    falling_y = 0
    for i=1, 4*4 do
        table.insert(falling, 0)
    end
    
    --defines game parameters
    game = {
        current_score=0,
        high_score=0,
        update_move=0,
        update_fall=0,
        refresh_move=1/30,
        refresh_fall=1/2,
        next_piece=pieces.I,
        input_last="none",
        input_rebounce=false
    }
    
    math.randomseed(os.time())
    new_piece(game.next_piece, 2, 0)
    game.next_piece = pieces[pieces_list[math.random(1, #pieces_list)]]
end

function love.update(dt)
    --game loop
        if love.keyboard.isDown("left") then
            game.input_last = "left"
        elseif love.keyboard.isDown("right") then
            game.input_last = "right"
        elseif love.keyboard.isDown("up") then
            game.input_last = "rotate"
        elseif love.keyboard.isDown("down") then
            game.input_last = "drop"
        else
            game.input_last = "none"
            game.input_rebounce = false
        end

    game.update_move = game.update_move + dt
    if game.update_move>game.refresh_move then
        game.update_move = 0
        if not game.input_rebounce then
            if game.input_last == "left" then
                move_piece(-1, 0)
                game.input_rebounce = true
            elseif game.input_last == "right" then
                move_piece(1, 0)
                game.input_rebounce = true
            elseif game.input_last == "rotate" then
                rotate_piece(1)
                game.input_rebounce = true
            elseif game.input_last == "drop" then
                move_piece(0, 1)
            end
        end
    end
    
    game.update_fall = game.update_fall + dt
    if game.update_fall>game.refresh_fall then
        game.update_fall = 0
        move_piece(0, 1)
    end
    
    clear_lines()
end

function love.draw()
    --game background
    love.graphics.setColor(32, 32, 32)
    love.graphics.rectangle("fill", 0, 0, 40*room_width, 40*room_height)
    love.graphics.setColor(32, 32, 64)
    love.graphics.rectangle("fill", 40*room_width, 0, 40*8, 40*12)
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("fill", 40*(room_width+2), 40*1.5, 40*4, 40*4)
    
    --game pieces
    draw_matrix(room, room_width, 0, 0)
    draw_matrix(falling, 4, falling_x, falling_y)
    draw_matrix(game.next_piece, 4, 10, 1.5)
    
    --game interface
    love.graphics.setColor(255, 255, 255)
    love.graphics.print("Next piece:", 9.5*40, 0, 0, 3, 3)
    love.graphics.print("Current score:", 8*40, 6*40, 0, 3, 3)
    love.graphics.print("High score:", 8*40, 9*40, 0, 3, 3)
    love.graphics.print(tostring(game.current_score), 8*40, 7*40, 0, 3, 3)
    love.graphics.print(tostring(game.high_score), 8*40, 10*40, 0, 3, 3)
end
