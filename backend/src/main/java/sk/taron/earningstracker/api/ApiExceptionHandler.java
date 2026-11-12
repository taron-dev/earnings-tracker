package sk.taron.earningstracker.api;

import java.net.URI;

import org.springframework.http.HttpStatus;
import org.springframework.http.ProblemDetail;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.servlet.mvc.method.annotation.ResponseEntityExceptionHandler;

/**
 * Turns exceptions into RFC 9457 problem details. The base class covers Spring MVC errors
 * such as Bean Validation and unreadable JSON.
 */
@RestControllerAdvice
public class ApiExceptionHandler extends ResponseEntityExceptionHandler {

    /** A broken domain rule, for example a zero hourly rate. */
    @ExceptionHandler(IllegalArgumentException.class)
    ProblemDetail invalidInput(IllegalArgumentException exception) {
        return ProblemDetail.forStatusAndDetail(HttpStatus.BAD_REQUEST, exception.getMessage());
    }

    /** The client can tell this conflict apart by its type and send the user to set a rate. */
    @ExceptionHandler(HourlyRateNotSetException.class)
    ProblemDetail hourlyRateNotSet(HourlyRateNotSetException exception) {
        ProblemDetail problem = ProblemDetail.forStatusAndDetail(HttpStatus.CONFLICT, exception.getMessage());
        problem.setType(URI.create("/problems/hourly-rate-not-set"));
        return problem;
    }

    @ExceptionHandler(OverlappingPlanException.class)
    ProblemDetail overlappingPlan(OverlappingPlanException exception) {
        ProblemDetail problem = ProblemDetail.forStatusAndDetail(HttpStatus.CONFLICT, exception.getMessage());
        problem.setType(URI.create("/problems/overlapping-plan"));
        return problem;
    }

    @ExceptionHandler(NotFoundException.class)
    ProblemDetail notFound(NotFoundException exception) {
        return ProblemDetail.forStatusAndDetail(HttpStatus.NOT_FOUND, exception.getMessage());
    }
}
