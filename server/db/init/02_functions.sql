-- Function to update card progress using SM-2 algorithm
CREATE OR REPLACE FUNCTION update_card_progress(
    p_user_id UUID,
    p_card_id UUID,
    p_confidence INTEGER
)
RETURNS UUID
LANGUAGE plpgsql
AS $$
DECLARE
    v_easiness FLOAT;
    v_repetition INTEGER;
    v_interval INTEGER;
    v_next_review TIMESTAMP WITH TIME ZONE;
    v_progress_id UUID;
BEGIN
    -- Check if user progress record exists
    SELECT id, easiness_factor, repetition, interval_days
    INTO v_progress_id, v_easiness, v_repetition, v_interval
    FROM user_progress
    WHERE user_id = p_user_id AND card_id = p_card_id;
    
    -- If no record exists, create one
    IF v_progress_id IS NULL THEN
        INSERT INTO user_progress (
            user_id, 
            card_id, 
            confidence_level,
            last_reviewed
        ) VALUES (
            p_user_id, 
            p_card_id, 
            p_confidence,
            CURRENT_TIMESTAMP
        )
        RETURNING id INTO v_progress_id;
        
        -- For new cards, set next review based on confidence
        UPDATE user_progress
        SET next_review_date = 
            CASE 
                WHEN p_confidence < 3 THEN CURRENT_TIMESTAMP + INTERVAL '1 day'
                WHEN p_confidence < 4 THEN CURRENT_TIMESTAMP + INTERVAL '2 days'
                ELSE CURRENT_TIMESTAMP + INTERVAL '4 days'
            END
        WHERE id = v_progress_id;
        
        RETURN v_progress_id;
    END IF;
    
    -- Apply SM-2 algorithm
    -- Calculate easiness factor
    v_easiness := v_easiness + (0.1 - (5 - p_confidence) * (0.08 + (5 - p_confidence) * 0.02));
    IF v_easiness < 1.3 THEN
        v_easiness := 1.3;
    END IF;
    
    -- Calculate repetition and interval
    IF p_confidence < 3 THEN
        -- If response was poor, reset repetition count
        v_repetition := 0;
        v_interval := 1;
    ELSE
        -- Increase repetition count
        v_repetition := v_repetition + 1;
        
        -- Calculate new interval
        IF v_repetition = 1 THEN
            v_interval := 1;
        ELSIF v_repetition = 2 THEN
            v_interval := 6;
        ELSE
            v_interval := ROUND(v_interval * v_easiness);
        END IF;
    END IF;
    
    -- Calculate next review date
    v_next_review := CURRENT_TIMESTAMP + (v_interval * INTERVAL '1 day');
    
    -- Update progress record
    UPDATE user_progress
    SET 
        repetition = v_repetition,
        easiness_factor = v_easiness,
        interval_days = v_interval,
        confidence_level = p_confidence,
        next_review_date = v_next_review,
        last_reviewed = CURRENT_TIMESTAMP
    WHERE id = v_progress_id;
    
    RETURN v_progress_id;
END;
$$;

-- Function to get cards due for review
CREATE OR REPLACE FUNCTION get_due_cards(
    user_uuid UUID,
    limit_count INTEGER DEFAULT 20
)
RETURNS TABLE (
    card_id UUID,
    question TEXT,
    answer TEXT,
    hint TEXT,
    set_id UUID,
    set_title TEXT,
    repetition INTEGER,
    easiness_factor FLOAT,
    interval_days INTEGER,
    confidence_level INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        f.id AS card_id,
        f.question,
        f.answer,
        f.hint,
        fs.id AS set_id,
        fs.title AS set_title,
        up.repetition,
        up.easiness_factor,
        up.interval_days,
        up.confidence_level
    FROM flashcards f
    JOIN flashcard_sets fs ON f.set_id = fs.id
    JOIN user_progress up ON f.id = up.card_id
    WHERE up.user_id = user_uuid
      AND up.next_review_date <= CURRENT_TIMESTAMP
      AND (fs.user_id = user_uuid OR fs.is_public = TRUE)
    ORDER BY up.next_review_date ASC
    LIMIT limit_count;
END;
$$;
