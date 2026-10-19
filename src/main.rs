use std::process::ExitCode;

fn main() -> ExitCode {
    let instance = match parse_instance_arg(std::env::args().skip(1)) {
        Ok(instance) => instance,
        Err(message) => {
            eprintln!("cbar: {message}");
            return ExitCode::from(2);
        }
    };

    tracing_subscriber::fmt::init();
    let _ = tracing_log::LogTracer::init();
    cbar::localize();

    match cbar::run(instance) {
        Ok(()) => ExitCode::SUCCESS,
        Err(err) => {
            eprintln!("cbar: {err}");
            ExitCode::FAILURE
        }
    }
}

fn parse_instance_arg(mut args: impl Iterator<Item = String>) -> Result<Option<String>, String> {
    let Some(arg) = args.next() else {
        return Ok(None);
    };
    if arg != "--instance" {
        return Err(format!(
            "unknown argument '{arg}' (usage: cbar [--instance <name>])"
        ));
    }
    let name = args
        .next()
        .ok_or_else(|| "--instance requires a name".to_owned())?;
    cbar::validate_instance_name(&name)?;
    Ok(Some(name))
}
