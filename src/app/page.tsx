import HomeStyle from './page.module.css'

export default function App() {
    return (
        <div className={HomeStyle.HomeContainer}>
            <nav>
                <h1>V Farm</h1>
                <ul>
                    <a href="">Home</a>
                    <a href="">Features</a>
                    <a href="">About</a>
                    <a href="">How it works ?</a>
                </ul>
                <a href="">Download <i className="bx bx-arrow-to-bottom" /></a>
            </nav>
            <section className={HomeStyle.Home}>
                <div className={HomeStyle.HomeContext}>
                    <p>We Farm , We Evolve</p>
                    <p>VFarm makes farming simple with easy tools and instant access to schemes, weather, and expert advice.
                        Fast, secure, and built to support every farmer’s success.</p>
                    <ul>
                        <a href="">Explore <i className="bx bx-arrow-in-up-right-circle" /> </a>
                    </ul>
                </div>
                <div className={HomeStyle.HomeDownload}>
                    
                </div>
                <div className={HomeStyle.HomeImage}>

                </div>
            </section>
        </div>
    )
}